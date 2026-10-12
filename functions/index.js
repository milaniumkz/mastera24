const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const functionsV1 = require("firebase-functions/v1");
const admin = require("firebase-admin");
const crypto = require("crypto");
const {
  buildFunctionUrl,
  normalizePayload,
  isApprovedPayload,
  buildInvoiceResponse,
} = require("./payment_helpers");

admin.initializeApp();

const REGION = "asia-southeast1";
const PAYMENT_STATUS = {
  created: "created",
  sdkStarted: "sdk_started",
  awaitingCallback: "awaiting_callback",
  paid: "paid",
  failed: "failed",
  cancelled: "cancelled",
  refundRequested: "refund_requested",
  refunded: "refunded"
};
const BID_STATUS = {
  pendingPayment: "pending_payment",
  submitted: "submitted",
  accepted: "accepted",
  rejected: "rejected"
};
const ACTIVE_PAYMENT_STATUSES = [
  PAYMENT_STATUS.created,
  PAYMENT_STATUS.sdkStarted,
  PAYMENT_STATUS.awaitingCallback
];

setGlobalOptions({ region: REGION });

const db = admin.firestore();
const serverTimestamp = admin.firestore.FieldValue.serverTimestamp;

const EPAY_ENV = process.env.EPAY_ENV || "unset";
const EPAY_CLIENT_ID = process.env.EPAY_CLIENT_ID || "";
const EPAY_CLIENT_SECRET = process.env.EPAY_CLIENT_SECRET || "";
const EPAY_TERMINAL_ID = process.env.EPAY_TERMINAL_ID || "";

const EPAY_TOKEN_URL =
  EPAY_ENV === "prod"
    ? "https://epay-oauth.homebank.kz/oauth2/token"
    : "https://test-epay-oauth.epayment.kz/oauth2/token";

const EPAY_CURRENCY = "KZT";
const EPAY_SCOPE =
  "webapi usermanagement email_send verification statement statistics payment";

const EPAY_REFUND_URL =
  EPAY_ENV === "prod"
    ? "https://epay-api.homebank.kz/operation"
    : "https://test-epay-api.epayment.kz/operation";

function assertAuthenticated(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Нужно заново войти в аккаунт.");
  }
}

function assertEpayConfigured({ requireTerminal = true } = {}) {
  if (!["test", "prod"].includes(EPAY_ENV)) {
    throw new HttpsError(
      "failed-precondition",
      "Платежный модуль не настроен для этой среды."
    );
  }

  if (!EPAY_CLIENT_ID || !EPAY_CLIENT_SECRET || (requireTerminal && !EPAY_TERMINAL_ID)) {
    throw new HttpsError(
      "failed-precondition",
      "Платежный модуль пока не настроен."
    );
  }
}

async function getUserTokens(uid) {
  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists) return [];
  const data = userSnap.data();
  return Array.isArray(data.fcmTokens) ? data.fcmTokens.filter(Boolean) : [];
}

function buildPushData(data) {
  return Object.fromEntries(
    Object.entries(data)
      .filter(([, value]) => value !== null && value !== undefined)
      .map(([key, value]) => [key, String(value)])
  );
}

function normalizeText(value) {
  return String(value || "").trim().toLowerCase();
}

function userMatchesJobCity(user, job) {
  const userCity = normalizeText(user.city);
  const jobCity = normalizeText(job.city);
  if (!userCity || !jobCity || userCity !== jobCity) return false;

  const userRegion = normalizeText(user.cityRegion);
  const jobRegion = normalizeText(job.cityRegion);
  return !userRegion || !jobRegion || userRegion === jobRegion;
}

function userWantsJobCategory(user, role, category) {
  const byRole = user.notificationCategoriesByRole || {};
  const selected = Array.isArray(byRole[role]) ? byRole[role] : [];
  if (!selected.length) return true;
  const normalizedCategory = normalizeText(category);
  return selected.some((item) => normalizeText(item) === normalizedCategory);
}

async function sendPushNotification(uid, payload) {
  const tokens = await getUserTokens(uid);
  if (!tokens.length) return;
  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    ...payload
  });

  const staleTokens = [];
  response.responses.forEach((result, index) => {
    if (result.success) return;
    const code = result.error?.code || "";
    if (["messaging/invalid-registration-token", "messaging/registration-token-not-registered"].includes(code)) {
      staleTokens.push(tokens[index]);
    }
  });

  if (staleTokens.length) {
    await db.collection("users").doc(uid).set({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
      updatedAt: serverTimestamp(),
    }, { merge: true });
  }
}

async function notifyUser({ recipientId, type, title, body, data = {} }) {
  const notificationRef = db.collection("notifications").doc();
  const notificationPayload = {
    recipientId,
    type,
    title,
    body,
    data,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    readAt: null,
  };

  await notificationRef.set(notificationPayload);
  try {
    await sendPushNotification(recipientId, {
      notification: {
        title,
        body,
      },
      data: buildPushData({
        notificationId: notificationRef.id,
        type,
        ...data,
      }),
    });
  } catch (error) {
    console.error("Push notification failed", error);
  }
}

async function isAdmin(uid) {
  const userSnap = await db.collection("users").doc(uid).get();
  return userSnap.exists && userSnap.data().role === "admin";
}

function normalizePhone(value) {
  return String(value || "").replace(/\D/g, "");
}

function phoneAuthEmails(phoneNumber) {
  const normalized = normalizePhone(phoneNumber);
  return [
    `phone_${normalized}@mastera42.kz`,
    `phone_${normalized}@mastera24.app`
  ];
}

async function getBidFeeKzt() {
  const billingSnap = await db.collection("settings").doc("billing").get();
  const billing = billingSnap.exists ? billingSnap.data() : null;
  const fee = billing?.bidFeeKzt;
  return typeof fee === "number" && fee > 0 ? fee : 0;
}

async function getCategoryBidFeeKzt(categoryName) {
  if (!categoryName) {
    return 0;
  }

  const catalogsSnap = await db.collection("settings").doc("catalogs").get();
  if (!catalogsSnap.exists) {
    return 0;
  }

  const categories = catalogsSnap.data()?.categories;
  if (!Array.isArray(categories)) {
    return 0;
  }

  const normalized = String(categoryName).trim().toLowerCase();
  for (const category of categories) {
    const name = category?.name;
    const fee = category?.bidFeeKzt;
    if (typeof name === "string" &&
        name.trim().toLowerCase() === normalized &&
        typeof fee === "number" &&
        fee > 0) {
      return fee;
    }
  }

  return 0;
}

async function getJobBidFeeKzt(job) {
  const directFee = job?.bidFeeKzt;
  if (typeof directFee === "number" && directFee > 0) {
    return directFee;
  }

  const categoryFee = await getCategoryBidFeeKzt(job?.category);
  if (categoryFee > 0) {
    return categoryFee;
  }

  return getBidFeeKzt();
}

function buildInvoiceId() {
  const random = Math.floor(10 + Math.random() * 90);
  return `${Date.now()}${random}`.slice(0, 15);
}

exports.createPaymentInvoice = onCall(async (request) => {
  assertAuthenticated(request);
  assertEpayConfigured();

  const { bidId, jobId } = request.data || {};
  if (!bidId || !jobId) {
    throw new HttpsError("invalid-argument", "Не удалось подготовить счёт для оплаты.");
  }

  const bidRef = db.collection("bids").doc(bidId);
  const jobRef = db.collection("jobs").doc(jobId);

  const [bidSnap, jobSnap] = await Promise.all([bidRef.get(), jobRef.get()]);
  if (!bidSnap.exists || !jobSnap.exists) {
    throw new HttpsError("not-found", "Заявка или отклик больше не доступны.");
  }

  const bid = bidSnap.data();
  const job = jobSnap.data();
  if (bid.executorId !== request.auth.uid) {
    throw new HttpsError("permission-denied", "Нельзя оплатить чужой отклик.");
  }
  if (job.customerId !== bid.customerId) {
    throw new HttpsError("failed-precondition", "Данные заявки и отклика не совпадают.");
  }
  if (bid.status !== BID_STATUS.pendingPayment) {
    throw new HttpsError(
      "failed-precondition",
      "Отклик уже обработан. Обновите экран и попробуйте снова."
    );
  }

  const amount = await getJobBidFeeKzt(job);
  const existingPayments = await db
    .collection("payments")
    .where("bidId", "==", bidId)
    .where("executorId", "==", request.auth.uid)
    .where("status", "in", ACTIVE_PAYMENT_STATUSES)
    .limit(1)
    .get();

  if (!existingPayments.empty) {
    const existing = existingPayments.docs.first;
    const data = existing.data();
    await existing.ref.set({ updatedAt: serverTimestamp() }, { merge: true });
    return buildInvoiceResponse({
      paymentId: existing.id,
      invoiceId: data.invoiceId,
      amount: data.amount || amount,
      uid: request.auth.uid,
      email: request.auth.token.email,
      phone: request.auth.token.phone_number,
      environment: EPAY_ENV,
      region: REGION,
      projectId: process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT
    });
  }

  const paymentRef = db.collection("payments").doc();
  const paymentId = paymentRef.id;
  const invoiceId = buildInvoiceId();
  const secretHash = crypto.randomBytes(16).toString("hex");
  const invoice = buildInvoiceResponse({
    paymentId,
    invoiceId,
    amount,
    uid: request.auth.uid,
    email: request.auth.token.email,
    phone: request.auth.token.phone_number,
    environment: EPAY_ENV,
    region: REGION,
    projectId: process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT
  });

  await paymentRef.set({
    paymentId,
    bidId,
    jobId,
    executorId: request.auth.uid,
    customerId: bid.customerId,
    amount,
    currency: EPAY_CURRENCY,
    invoiceId,
    status: PAYMENT_STATUS.created,
    callbackStatus: "pending",
    environment: EPAY_ENV,
    secretHash,
    postLink: invoice.postLink,
    failurePostLink: invoice.failurePostLink,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    sdkStartedAt: null,
    paidAt: null,
    failedAt: null,
    cancelledAt: null
  });

  return invoice;
});

exports.resetPhonePassword = onCall(async (request) => {
  const phoneNumber = request.data?.phoneNumber;
  const newPassword = request.data?.newPassword;
  const normalizedPhone = normalizePhone(phoneNumber);

  if (normalizedPhone.length !== 11) {
    throw new HttpsError(
      "invalid-argument",
      "Введите номер телефона в формате +7 (###) ###-##-##."
    );
  }

  if (typeof newPassword !== "string" || newPassword.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Пароль должен быть не менее 6 символов."
    );
  }

  let targetUser = null;
  for (const email of phoneAuthEmails(phoneNumber)) {
    try {
      targetUser = await admin.auth().getUserByEmail(email);
      break;
    } catch (error) {
      if (error.code !== "auth/user-not-found") {
        throw error;
      }
    }
  }

  if (!targetUser) {
    throw new HttpsError("not-found", "Аккаунт с таким номером не найден.");
  }

  await admin.auth().updateUser(targetUser.uid, { password: newPassword });
  await db.collection("users").doc(targetUser.uid).set({
    passwordResetAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }, { merge: true });

  return { success: true };
});

exports.registerPaymentClientResult = onCall(async (request) => {
  assertAuthenticated(request);

  const { paymentId, status, payload } = request.data || {};
  if (!paymentId || !status) {
    throw new HttpsError("invalid-argument", "Не удалось обновить статус оплаты.");
  }

  const paymentRef = db.collection("payments").doc(paymentId);
  const paymentSnap = await paymentRef.get();
  if (!paymentSnap.exists) {
    throw new HttpsError("not-found", "Платёж не найден.");
  }

  const payment = paymentSnap.data();
  if (payment.executorId !== request.auth.uid) {
    throw new HttpsError("permission-denied", "Недостаточно прав для обновления оплаты.");
  }

  const nextStatus = String(status);
  if (![
    PAYMENT_STATUS.sdkStarted,
    PAYMENT_STATUS.awaitingCallback,
    PAYMENT_STATUS.failed,
    PAYMENT_STATUS.cancelled
  ].includes(nextStatus)) {
    throw new HttpsError("invalid-argument", "Недопустимый статус оплаты.");
  }

  if ([PAYMENT_STATUS.paid, PAYMENT_STATUS.refundRequested, PAYMENT_STATUS.refunded].includes(payment.status)) {
    return { status: payment.status, locked: true };
  }

  const update = {
    status: nextStatus,
    clientPayload: payload || {},
    updatedAt: serverTimestamp()
  };

  if (nextStatus === PAYMENT_STATUS.sdkStarted) {
    update.sdkStartedAt = serverTimestamp();
  }
  if (nextStatus === PAYMENT_STATUS.awaitingCallback) {
    update.awaitingCallbackAt = serverTimestamp();
  }
  if (nextStatus === PAYMENT_STATUS.failed) {
    update.failedAt = serverTimestamp();
  }
  if (nextStatus === PAYMENT_STATUS.cancelled) {
    update.cancelledAt = serverTimestamp();
  }

  await paymentRef.set(update, { merge: true });
  return { status: nextStatus };
});

async function handleEpayCallback(req, res, { forceFailure = false } = {}) {
  try {
    const paymentId = req.query.paymentId;
    const payload = normalizePayload(req.body);

    if (!paymentId) {
      res.status(400).send("Missing paymentId");
      return;
    }

    const paymentRef = db.collection("payments").doc(String(paymentId));

    await db.runTransaction(async (transaction) => {
      const paymentSnap = await transaction.get(paymentRef);
      if (!paymentSnap.exists) {
        throw new HttpsError("not-found", "Payment not found");
      }

      const payment = paymentSnap.data();
      const bidRef = db.collection("bids").doc(payment.bidId);
      const bidSnap = await transaction.get(bidRef);
      if (!bidSnap.exists) {
        throw new HttpsError("not-found", "Bid not found");
      }

      if (payload.secret_hash && payment.secretHash && payload.secret_hash !== payment.secretHash) {
        transaction.set(paymentRef, {
          status: PAYMENT_STATUS.failed,
          callbackStatus: "hash_mismatch",
          payload,
          failedAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        }, { merge: true });
        throw new HttpsError("permission-denied", "Invalid signature");
      }

      const approved = isApprovedPayload(payload, forceFailure);
      const operationId = payload.id || payload.operation_id || payload.operationId || null;
      const bid = bidSnap.data();

      if (approved) {
        transaction.set(paymentRef, {
          status: PAYMENT_STATUS.paid,
          callbackStatus: "approved",
          payload,
          operationId,
          paidAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        }, { merge: true });

        if (bid.status === BID_STATUS.pendingPayment) {
          transaction.set(bidRef, {
            status: BID_STATUS.submitted,
            paymentId: paymentRef.id,
            submittedAt: serverTimestamp(),
            updatedAt: serverTimestamp()
          }, { merge: true });
        }
        return;
      }

      if (payment.status !== PAYMENT_STATUS.paid) {
        transaction.set(paymentRef, {
          status: forceFailure ? PAYMENT_STATUS.failed : PAYMENT_STATUS.cancelled,
          callbackStatus: forceFailure ? "failure_callback" : "declined",
          payload,
          operationId,
          failedAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        }, { merge: true });

        if (bid.status === BID_STATUS.pendingPayment) {
          transaction.set(bidRef, {
            updatedAt: serverTimestamp(),
            lastPaymentStatus: forceFailure ? PAYMENT_STATUS.failed : PAYMENT_STATUS.cancelled
          }, { merge: true });
        }
      }
    });

    res.status(200).send("OK");
  } catch (error) {
    if (error instanceof HttpsError) {
      res.status(error.code === "permission-denied" ? 403 : 404).send(error.message);
      return;
    }
    res.status(500).send("Server error");
  }
}

exports.epayPostLink = onRequest(async (req, res) => {
  await handleEpayCallback(req, res, { forceFailure: false });
});

exports.epayFailurePostLink = onRequest(async (req, res) => {
  await handleEpayCallback(req, res, { forceFailure: true });
});

exports.refundPayment = onCall(async (request) => {
  assertAuthenticated(request);
  assertEpayConfigured({ requireTerminal: false });

  const uid = request.auth.uid;
  if (!(await isAdmin(uid))) {
    throw new HttpsError("permission-denied", "Только администратор может оформить возврат.");
  }

  const { paymentId, amount } = request.data || {};
  if (!paymentId) {
    throw new HttpsError("invalid-argument", "Не удалось определить платёж для возврата.");
  }

  const paymentRef = db.collection("payments").doc(paymentId);
  const paymentSnap = await paymentRef.get();
  if (!paymentSnap.exists) {
    throw new HttpsError("not-found", "Платёж не найден.");
  }

  const payment = paymentSnap.data();
  if (payment.status === PAYMENT_STATUS.refundRequested || payment.status === PAYMENT_STATUS.refunded) {
    throw new HttpsError("already-exists", "Возврат по этому платежу уже запрошен.");
  }
  if (payment.status !== PAYMENT_STATUS.paid) {
    throw new HttpsError("failed-precondition", "Возврат доступен только для успешной оплаты.");
  }

  const operationId = payment.operationId;
  if (!operationId) {
    throw new HttpsError("failed-precondition", "У платежа нет идентификатора операции для возврата.");
  }

  const tokenPayload = new URLSearchParams({
    grant_type: "client_credentials",
    scope: EPAY_SCOPE,
    client_id: EPAY_CLIENT_ID,
    client_secret: EPAY_CLIENT_SECRET
  });

  const tokenResponse = await fetch(EPAY_TOKEN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body: tokenPayload.toString()
  });

  if (!tokenResponse.ok) {
    throw new HttpsError("unavailable", "Платёжный шлюз временно недоступен.");
  }

  const auth = await tokenResponse.json();
  const accessToken = auth.access_token || auth.accessToken;
  if (!accessToken) {
    throw new HttpsError("unavailable", "Не удалось авторизоваться в платёжном шлюзе.");
  }

  const query = typeof amount === "number" && amount > 0
    ? `?amount=${amount}&externalID=${paymentId}`
    : `?externalID=${paymentId}`;
  const refundUrl = `${EPAY_REFUND_URL}/${operationId}/refund${query}`;

  const refundResponse = await fetch(refundUrl, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`
    }
  });

  if (!refundResponse.ok) {
    throw new HttpsError("unavailable", "Не удалось оформить возврат. Повторите позже.");
  }

  await paymentRef.set({
    status: PAYMENT_STATUS.refundRequested,
    refundAmount: typeof amount === "number" ? amount : null,
    refundRequestedBy: uid,
    refundRequestedAt: serverTimestamp(),
    updatedAt: serverTimestamp()
  }, { merge: true });

  return { success: true, status: PAYMENT_STATUS.refundRequested };
});

exports.onBidStatusChanged = functionsV1
  .region(REGION)
  .firestore.document("bids/{bidId}")
  .onUpdate(async (change, context) => {
  const before = change.before.data();
  const after = change.after.data();
  if (!before || !after) return;

  if (before.status === after.status) return;

  if (after.status === BID_STATUS.submitted) {
    await notifyUser({
      recipientId: after.customerId,
      type: "new_bid",
      title: "Новый чат по заказу",
      body: "Исполнитель открыл чат по вашей заявке.",
      data: {
        bidId: context.params.bidId,
        jobId: after.jobId,
      },
    });
    return;
  }

  if (![BID_STATUS.accepted, BID_STATUS.rejected].includes(after.status)) {
    return;
  }

  const statusText = after.status === BID_STATUS.accepted ? "принят" : "отклонён";

  await notifyUser({
    recipientId: after.executorId,
    type: "bid_status",
    title: "Статус отклика",
    body: `Ваш отклик ${statusText}.`,
    data: {
      bidId: context.params.bidId,
      jobId: after.jobId,
      status: after.status,
    },
  });
});

exports.onBidCreated = functionsV1
  .region(REGION)
  .firestore.document("bids/{bidId}")
  .onCreate(async (snapshot, context) => {
    const bid = snapshot.data();
    if (!bid || bid.status !== BID_STATUS.submitted) return;
    if (!bid.customerId || !bid.jobId) return;

    await notifyUser({
      recipientId: bid.customerId,
      type: "new_bid",
      title: "Новый чат по заказу",
      body: "Исполнитель открыл чат по вашей заявке.",
      data: {
        bidId: context.params.bidId,
        jobId: bid.jobId,
      },
    });
  });

exports.onJobCreated = functionsV1
  .region(REGION)
  .firestore.document("jobs/{jobId}")
  .onCreate(async (snapshot, context) => {
    const job = snapshot.data();
    if (!job || job.status !== "open") return;

    const ownerRole = job.ownerRole === "executor" ? "executor" : "customer";
    const targetRole = ownerRole === "executor" ? "customer" : "executor";
    const usersSnap = await db.collection("users")
      .where("role", "==", targetRole)
      .where("status", "==", "active")
      .get();

    const notifications = [];
    usersSnap.forEach((doc) => {
      if (doc.id === job.customerId) return;
      const user = doc.data();
      if (!userMatchesJobCity(user, job)) return;
      if (!userWantsJobCategory(user, targetRole, job.category)) return;

      notifications.push(notifyUser({
        recipientId: doc.id,
        type: "new_job",
        title: "Новый заказ",
        body: `${job.category || "Заявка"} · ${job.city || ""}`.trim(),
        data: {
          jobId: context.params.jobId,
          targetRole,
          ownerRole,
          category: job.category || "",
          city: job.city || "",
        },
      }));
    });

    await Promise.all(notifications);
  });

exports.onChatMessageCreated = functionsV1
  .region(REGION)
  .firestore.document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    if (!message) return;

    const chatSnap = await db.collection("chats").doc(context.params.chatId).get();
    if (!chatSnap.exists) return;
    const chat = chatSnap.data();

    const recipientId = message.senderId === chat.customerId ? chat.executorId : chat.customerId;
    await notifyUser({
      recipientId,
      type: "chat_message",
      title: "Новое сообщение",
      body: message.text || chat.lastMessageText || "У вас новое сообщение.",
      data: {
        chatId: context.params.chatId,
        messageId: context.params.messageId,
        bidId: chat.bidId || "",
        jobId: chat.jobId || "",
      },
    });
  });

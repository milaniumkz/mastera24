function buildFunctionUrl({ functionName, projectId, region }) {
  if (!projectId) return "";
  return `https://${region}-${projectId}.cloudfunctions.net/${functionName}`;
}

function normalizePayload(body) {
  if (!body) return {};
  if (typeof body === "string") {
    try {
      return JSON.parse(body);
    } catch (_) {
      return {};
    }
  }
  return body;
}

function isApprovedPayload(payload, forceFailure = false) {
  if (forceFailure) {
    return false;
  }
  return (
    payload.approved === true ||
    payload.approved === "true" ||
    payload.code === "00" ||
    payload.status === "SUCCESS" ||
    payload.status === "APPROVED"
  );
}

function buildInvoiceResponse({
  paymentId,
  invoiceId,
  amount,
  uid,
  email,
  phone,
  environment,
  region,
  projectId,
}) {
  const postLinkBase = buildFunctionUrl({
    functionName: "epayPostLink",
    projectId,
    region,
  });
  const failurePostLinkBase = buildFunctionUrl({
    functionName: "epayFailurePostLink",
    projectId,
    region,
  });
  const postLink = postLinkBase ? `${postLinkBase}?paymentId=${paymentId}` : "";
  const failurePostLink = failurePostLinkBase
    ? `${failurePostLinkBase}?paymentId=${paymentId}`
    : postLink;

  return {
    paymentId,
    invoiceId,
    amount,
    currency: "KZT",
    postLink,
    failurePostLink,
    description: "Отклик на заявку Mastera24",
    accountId: uid,
    email: email || "",
    phone: phone || "",
    environment,
  };
}

module.exports = {
  buildFunctionUrl,
  normalizePayload,
  isApprovedPayload,
  buildInvoiceResponse,
};

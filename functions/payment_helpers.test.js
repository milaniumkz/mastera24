const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildFunctionUrl,
  normalizePayload,
  isApprovedPayload,
  buildInvoiceResponse,
} = require("./payment_helpers");

test("buildFunctionUrl returns empty string without project id", () => {
  assert.equal(
    buildFunctionUrl({
      functionName: "epayPostLink",
      projectId: "",
      region: "asia-southeast1",
    }),
    "",
  );
});

test("buildFunctionUrl builds HTTPS URL for region and function", () => {
  assert.equal(
    buildFunctionUrl({
      functionName: "epayPostLink",
      projectId: "mastera24-b48e2",
      region: "asia-southeast1",
    }),
    "https://asia-southeast1-mastera24-b48e2.cloudfunctions.net/epayPostLink",
  );
});

test("normalizePayload parses JSON strings and ignores invalid JSON", () => {
  assert.deepEqual(normalizePayload('{"ok":true}'), { ok: true });
  assert.deepEqual(normalizePayload("{bad json"), {});
  assert.deepEqual(normalizePayload(null), {});
});

test("isApprovedPayload recognizes approved payment states", () => {
  assert.equal(isApprovedPayload({ approved: true }), true);
  assert.equal(isApprovedPayload({ approved: "true" }), true);
  assert.equal(isApprovedPayload({ code: "00" }), true);
  assert.equal(isApprovedPayload({ status: "SUCCESS" }), true);
  assert.equal(isApprovedPayload({ status: "APPROVED" }), true);
  assert.equal(isApprovedPayload({ status: "SUCCESS" }, true), false);
});

test("buildInvoiceResponse composes callback links and defaults", () => {
  const response = buildInvoiceResponse({
    paymentId: "pay-1",
    invoiceId: "inv-1",
    amount: 12000,
    uid: "user-1",
    email: "",
    phone: null,
    environment: "prod",
    region: "asia-southeast1",
    projectId: "mastera24-b48e2",
  });

  assert.equal(response.currency, "KZT");
  assert.equal(response.accountId, "user-1");
  assert.equal(
    response.postLink,
    "https://asia-southeast1-mastera24-b48e2.cloudfunctions.net/epayPostLink?paymentId=pay-1",
  );
  assert.equal(
    response.failurePostLink,
    "https://asia-southeast1-mastera24-b48e2.cloudfunctions.net/epayFailurePostLink?paymentId=pay-1",
  );
  assert.equal(response.email, "");
  assert.equal(response.phone, "");
});

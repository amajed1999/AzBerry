# AzBerry — Edge Functions

Deno/TypeScript functions running on Supabase (project `azberry`).

## Functions

### `place-order`  (verify_jwt: true)
The **secure checkout path**. Never trusts client-sent prices.
1. Identifies the user from their JWT.
2. Recomputes every price from the DB with the service role
   (base price + branch `price_override` + size modifier + add-ons).
3. Enforces branch `min_order`, availability, tax rate (from the branch's country),
   delivery fee, and the promo code.
4. Inserts `orders` + `order_items` atomically and records promo usage.

Request:
```jsonc
POST /functions/v1/place-order      // Authorization: Bearer <user JWT>
{
  "branch_id": "…",
  "order_type": "delivery" | "pickup",
  "payment_method": "cash",
  "promo_code": "WELCOME10",         // optional
  "items": [
    { "product_id": "…", "size_id": "…", "addon_ids": ["…"], "quantity": 2, "notes": "" }
  ]
}
```
Response: `{ "order_id": "…", "breakdown": { subtotal, discount, delivery_fee, tax, total } }`

> ✅ Verified: a tampered `unit_price` in the request is ignored — the server
> recomputes it. Tested: 2× Mango Slush (large) + WELCOME10 → total 11000.

### `validate-promo`  (verify_jwt: false)
Read-only. Validates a code for the **cart preview** (callable by guests).
Reads `promo_codes` with the service role (hidden from clients by RLS).

Request:
```jsonc
POST /functions/v1/validate-promo
{ "code": "WELCOME10", "branch_id": "…", "subtotal": 10000 }
```
Response: `{ valid, message, type, discount, delivery_waived, promo_id? }`

## Redeploy
Via Supabase MCP `deploy_edge_function`, or the CLI:
```bash
supabase functions deploy place-order
supabase functions deploy validate-promo --no-verify-jwt
```

## Wiring the Flutter app to place-order
Replace the direct insert in `OrdersRepository.placeOrder` with:
```dart
final res = await supabase.functions.invoke('place-order', body: {
  'branch_id': branchId,
  'order_type': orderType,
  'payment_method': paymentMethod,
  'promo_code': promoCode,
  'items': items.map((c) => {
    'product_id': c.product.id,
    'size_id': c.size?.id,
    'addon_ids': c.addons.map((a) => a.id).toList(),
    'quantity': c.quantity,
    'notes': c.notes,
  }).toList(),
});
final orderId = (res.data as Map)['order_id'] as String;
```

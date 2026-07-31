# Cup Tales admin order contract

The customer app writes fulfillment and contact details directly to the
`public.orders` row. The admin dashboard should read these fields as follows.

| Database field | Type | Admin meaning |
| --- | --- | --- |
| `fulfillment_type` | text | `pickup`, `drive_thru`, or `delivery` |
| `branch_id` | text / nullable | Selected branch for pickup and drive-thru; null for delivery |
| `branch_name` | text / nullable | Branch display snapshot |
| `delivery_address` | text / nullable | Required only when `fulfillment_type = delivery` |
| `customer_note` | text / nullable | Drive-thru vehicle details, for example vehicle type and color |
| `customer_phone` | text | Customer phone snapshot captured when the order is created |
| `payment_method` | text | Currently `cash` |
| `promo_code` | text / nullable | Applied promo code |
| `discount_amount` | numeric | Applied discount amount |

Important: delivery orders intentionally have no branch. Do not exclude rows
with a null `branch_id`; instead route them to the delivery queue.

Suggested labels:

- `pickup`: استلام من الفرع
- `drive_thru`: Drive-thru
- `delivery`: توصيل للمنزل

The database rejects every new order unless the customer's current profile has
a valid Egyptian mobile number matching `01[0125]XXXXXXXX`. A copy is stored in
`orders.customer_phone`, so later profile edits do not alter existing orders.

Orders are accepted daily from 07:30 through 00:30:59 in the Africa/Cairo time
zone. The database trigger is the source of truth even if a client bypasses the
closed-hours screen.

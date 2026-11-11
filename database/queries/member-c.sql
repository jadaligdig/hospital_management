-- R7 Billing Summary
-- Member C: KC Cimafranca

SELECT
i.invoice_id,
i.admission_id,
i.total_amount,
i.amount_paid,
i.status,
p.payment_id,
p.amount AS payment_amount,
p.method,
p.paid_at
FROM invoices AS i
INNER JOIN payments AS p
ON i.invoice_id = p.invoice_id
ORDER BY i.invoice_id;
# orders

Order lines and their storage for the shop.

- Test: `python3 -m unittest discover -s tests`
- Deploy: four workers behind the load balancer, replaced one at a time. The files in
  `migrations/` run in order before the first worker is replaced, so old and new workers serve
  requests together for a few minutes.

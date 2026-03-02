# Alias so Administrate can resolve "saas_plans" resource → SaasPlan → Saas::Plan.
# Administrate calls resource_name.classify.constantize, producing "SaasPlan".
SaasPlan = Saas::Plan

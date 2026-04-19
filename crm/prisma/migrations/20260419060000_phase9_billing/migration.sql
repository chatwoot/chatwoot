ALTER TABLE "Account" ADD COLUMN "plan" TEXT NOT NULL DEFAULT 'free';
ALTER TABLE "Account" ADD COLUMN "stripeCustomerId" TEXT;
ALTER TABLE "Account" ADD COLUMN "stripeSubscriptionId" TEXT;
ALTER TABLE "Account" ADD COLUMN "stripePriceId" TEXT;
ALTER TABLE "Account" ADD COLUMN "subscriptionStatus" TEXT;
CREATE UNIQUE INDEX "Account_stripeCustomerId_key" ON "Account"("stripeCustomerId");
CREATE UNIQUE INDEX "Account_stripeSubscriptionId_key" ON "Account"("stripeSubscriptionId");

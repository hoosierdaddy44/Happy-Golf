-- Migration: ratings, accolades, peer verifications

-- 1. Extend profiles with rating fields
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS rating       NUMERIC(3,2),
  ADD COLUMN IF NOT EXISTS rating_count INTEGER NOT NULL DEFAULT 0;

-- 2. Round ratings table
CREATE TABLE IF NOT EXISTS round_ratings (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tee_time_id  UUID NOT NULL REFERENCES tee_times(id) ON DELETE CASCADE,
  rater_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  ratee_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  score        SMALLINT NOT NULL CHECK (score BETWEEN 1 AND 5),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tee_time_id, rater_id, ratee_id),
  CONSTRAINT no_self_rating CHECK (rater_id != ratee_id)
);

ALTER TABLE round_ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert own ratings" ON round_ratings
  FOR INSERT WITH CHECK (auth.uid() = rater_id);
CREATE POLICY "Ratings readable by members" ON round_ratings
  FOR SELECT USING (auth.role() = 'authenticated');

-- 3. Trigger to recalculate average rating on profiles
CREATE OR REPLACE FUNCTION recalculate_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET
    rating       = (SELECT ROUND(AVG(score)::NUMERIC, 2) FROM round_ratings WHERE ratee_id = NEW.ratee_id),
    rating_count = (SELECT COUNT(*) FROM round_ratings WHERE ratee_id = NEW.ratee_id)
  WHERE id = NEW.ratee_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_rating ON round_ratings;
CREATE TRIGGER trg_update_rating
AFTER INSERT ON round_ratings
FOR EACH ROW EXECUTE FUNCTION recalculate_rating();

-- 4. Accolades table
CREATE TABLE IF NOT EXISTS accolades (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type        TEXT NOT NULL CHECK (type IN ('eagle','birdie_machine','broke_80','broke_70','hole_in_one','personal_best')),
  tee_time_id UUID REFERENCES tee_times(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE accolades ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can claim own accolades" ON accolades
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Accolades readable by members" ON accolades
  FOR SELECT USING (auth.role() = 'authenticated');

-- 5. Accolade verifications table
CREATE TABLE IF NOT EXISTS accolade_verifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  accolade_id UUID NOT NULL REFERENCES accolades(id) ON DELETE CASCADE,
  verifier_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (accolade_id, verifier_id)
);

ALTER TABLE accolade_verifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players can verify accolades" ON accolade_verifications
  FOR INSERT WITH CHECK (auth.uid() = verifier_id);
CREATE POLICY "Verifications readable by members" ON accolade_verifications
  FOR SELECT USING (auth.role() = 'authenticated');

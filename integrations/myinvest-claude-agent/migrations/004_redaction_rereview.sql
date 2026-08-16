CREATE OR REPLACE FUNCTION agent_validate_candidate_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = OLD.status THEN
    RETURN NEW;
  END IF;

  IF (OLD.status IN ('quarantined', 'pending_review') AND NEW.status IN ('approved', 'rejected'))
     OR (OLD.status = 'approved' AND NEW.status IN ('published', 'rejected', 'pending_review'))
     OR (OLD.status = 'published' AND NEW.status IN ('rejected', 'pending_review')) THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'invalid candidate status transition: % -> %', OLD.status, NEW.status;
END;
$$;

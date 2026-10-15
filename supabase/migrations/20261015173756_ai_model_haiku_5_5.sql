-- BigBack · AI model: Claude Haiku 5.5 (owner decision 2026-10-15). The ai-ask Edge Function reads the
-- model ID from app_config, so this switches it without an app release.
update public.app_config
set value = jsonb_set(value, '{model}', '"claude-haiku-5-5"'), updated_at = now()
where key = 'ai';

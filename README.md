## About this project

This is the dbt analytics layer for **[Feedbackito](https://feedbackito.com)** (a feedback-widget SaaS product built on the [ShipFast](https://shipfa.st) + Supabase template — product repo: `shipfast-template-supabse`). Raw data is synced via Fivetran from the product's Supabase/Postgres database (reviews, profiles, surveys, spaces, plans, ab_tests, presale_subscribers, user_quotas) plus Google Search Console, and modeled here through staging → marts.

It's a real personal project, not a throwaway sandbox — and it also doubles as hands-on practice for the **dbt Developer Certification**.

### Environments (targets)

| Target | Profile dataset | Models / seeds / snapshots land in | How to run |
|---|---|---|---|
| `dev` (default) | `dbt_dev` | `dbt_dev_public` / `dbt_dev` / `dbt_dev_snapshots` | `dbt build` |
| `prod` | `public` | `public` / `public` / `snapshots` | `dbt build --target prod` |
| `cloud` (Claude Code cloud) | `dbt_claude` | `dbt_claude_public` / `dbt_claude` / `dbt_claude_snapshots` | set up automatically |

`macros/generate_schema_name.sql` uses the custom schema as-is only on `prod`; every other target prefixes it with its own dataset. Sources always read the raw Fivetran datasets (`public`, `google_search_console`) regardless of target. Targets live in `~/.dbt/profiles.yml` (not committed).

### Claude Code cloud sessions

`.claude/settings.json` runs [`scripts/cloud_session_setup.sh`](scripts/cloud_session_setup.sh) on session start (a no-op locally). In the cloud it installs dbt Core + dbt-bigquery from `requirements.txt`, writes a `cloud` profile, and runs `dbt deps`. Cloud builds land in `dbt_claude_public`, never in prod `public`.

Cloud environment settings (claude.ai/code → environment selector):
- **Network:** Limited, package managers allowed, plus `hub.getdbt.com`
- **Environment variables:** `GCP_SA_KEY_B64=<base64 of the service-account JSON>`. These are visible to anyone using the environment, so use a dedicated least-privilege service account.

### Using the starter project

Try running the following commands:
- `dbt build` (dev)
- `dbt build --target prod` (production)


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices

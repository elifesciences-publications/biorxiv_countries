#!/bin/bash
set -e

pg_restore -U postgres --no-owner -d postgres /app/biorxiv_countries.postgres.backup

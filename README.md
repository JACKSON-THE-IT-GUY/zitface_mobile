# ZitFace Mobile

ZitFace is a Flutter campus social app backed by Supabase for authentication,
profiles, membership review, social features, messaging, cohorts, and listings.

## Supabase foundation

1. Create a Supabase project.
2. Open the project's SQL Editor and run these migrations in order:
   [`supabase/migrations/20261023100000_social_foundation.sql`](supabase/migrations/20261023100000_social_foundation.sql), then
   [`supabase/migrations/20261101000000_store_signup_sin_privately.sql`](supabase/migrations/20261101000000_store_signup_sin_privately.sql), then
   [`supabase/migrations/20261101010000_secure_member_identity_submission.sql`](supabase/migrations/20261101010000_secure_member_identity_submission.sql), then
   [`supabase/migrations/20261101020000_manual_membership_review.sql`](supabase/migrations/20261101020000_manual_membership_review.sql), then
   [`supabase/migrations/20261101030000_validate_cbu_student_sin.sql`](supabase/migrations/20261101030000_validate_cbu_student_sin.sql), then
   [`supabase/migrations/20261102000000_auto_approve_students.sql`](supabase/migrations/20261102000000_auto_approve_students.sql).
   Next, apply
   [`supabase/migrations/20261103000000_require_approved_membership.sql`](supabase/migrations/20261103000000_require_approved_membership.sql).
   Then apply
   [`supabase/migrations/20261104000000_private_post_media.sql`](supabase/migrations/20261104000000_private_post_media.sql).
   Then apply
   [`supabase/migrations/20261104010000_direct_messaging.sql`](supabase/migrations/20261104010000_direct_messaging.sql).
   Then apply
   [`supabase/migrations/20261104020000_require_manual_student_approval.sql`](supabase/migrations/20261104020000_require_manual_student_approval.sql).
   Then apply
   [`supabase/migrations/20261104030000_marketplace_listings.sql`](supabase/migrations/20261104030000_marketplace_listings.sql).
   Then apply
   [`supabase/migrations/20261105000000_auto_approve_valid_students.sql`](supabase/migrations/20261105000000_auto_approve_valid_students.sql).
   Then apply
   [`supabase/migrations/20261105010000_story_media.sql`](supabase/migrations/20261105010000_story_media.sql).
   Then apply
   [`supabase/migrations/20261108000000_marketplace_media.sql`](supabase/migrations/20261108000000_marketplace_media.sql)
   to enable marketplace photos.
   Then apply
   [`supabase/migrations/20261109000000_story_video_support.sql`](supabase/migrations/20261109000000_story_video_support.sql)
   to allow private MP4/MOV story videos up to 60 seconds.
   Finally, apply
   [`supabase/migrations/20261110000000_story_audio_uploads.sql`](supabase/migrations/20261110000000_story_audio_uploads.sql)
   to allow private, rights-confirmed story soundtracks.
   Then apply
   [`supabase/migrations/20261111000000_private_profile_avatars.sql`](supabase/migrations/20261111000000_private_profile_avatars.sql)
   to move profile photos to private storage with profile-visibility checks.
   Then apply
   [`supabase/migrations/20261112000000_profile_details.sql`](supabase/migrations/20261112000000_profile_details.sql)
   to add editable program, study year, interests, and website fields.
   It creates profiles, friend requests, follows, posts and media metadata,
   comments, reactions, stories and views, conversations and messages,
   notifications, academic cohorts, and linked groups. It also sets up the
   avatar storage bucket, indexes, and Row Level Security policies. New
   Supabase Auth users automatically receive a profile row.
3. Keep local Supabase values in an ignored `.env.local` file:

   ```dotenv
   SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_PUBLISHABLE_KEY
   ```

   Run or build with:

   ```sh
   flutter run --dart-define-from-file=.env.local
   flutter build web --release --dart-define-from-file=.env.local
   ```

   For a phone browser preview, serve `build/web` on `0.0.0.0` and open
   `http://YOUR_MAC_WIFI_IP:PORT/` on the phone connected to the same Wi-Fi.

For VS Code, choose **ZitFace (Supabase)** in Run and Debug. It uses this
project URL and prompts for the publishable key each launch; the key is not
saved in the workspace.

If both values are omitted, the app starts in local demo mode. Providing only
one value is an error. The publishable key (or legacy anon key) is intended for
client use and is protected by Row Level Security; never put a Supabase
service-role or secret key in the app.

For Android release builds, provide a private `android/key.properties` file
with `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`. Keep the
keystore and properties file out of source control. Release builds no longer
use the debug signing key.

With Supabase configured, authentication, profiles, membership review, feed
posts and reactions/comments, friend discovery and requests, direct messaging,
academic cohorts, group membership, and marketplace listings use the backend.
Stories support private photos and videos, captions, Friends/Public audiences,
24-hour expiry, playback controls, view counts, owner deletion, and private
user-uploaded soundtracks with a rights confirmation.
Account settings support display-name and password changes, private profiles,
signing out other sessions, and account deletion. Profile photos are served with
short-lived signed URLs after storage RLS checks the profile audience. Deploy
the account deletion function before enabling account creation:

```sh
supabase functions deploy delete-account --project-ref YOUR_PROJECT_REF
```

The function uses Supabase's server-side `SUPABASE_SERVICE_ROLE_KEY`; never add
that key to the Flutter app or client build settings. The in-app Privacy and
Terms page is a draft summary and must be replaced or approved by the operator
before public launch.
Marketplace photos use private cloud storage. Each published post earns one
contribution star, calculated from the member's current posts.
Profile names and photos appear in the feed, friends, direct chats, and
marketplace; cloud pages refresh member details when revisited. Sample group
discussions are not connected to member profiles.
Members can message discoverable profiles without waiting for a friend request
to be accepted. Materials, group discussions, and marketplace payments are not
implemented as cloud features yet. Without credentials, debug builds continue
in local demo mode (demo posts, stars, listings, photos, and messages last only
for the current app session);
release builds show an unavailable screen instead. Existing local profiles
and cohorts are not automatically imported into Supabase.

### CBU membership checks

Student IDs matching the configured format are automatically approved. The
eight-digit check, including a year prefix from `19` through `27`, validates
format only; it does not verify enrollment with CBU. Staff applications remain
pending until an administrator reviews them. To list pending staff applications:

```sql
select user_id, member_type, member_number, submitted_at
from private.member_identity
where status = 'pending'
   and member_type = 'staff'
order by submitted_at;
```

After verifying an applicant with CBU, approve their UUID:

```sql
update private.member_identity
set status = 'approved', reviewed_at = now()
where user_id = 'USER_UUID_HERE'
   and status = 'pending';
```

Use `status = 'rejected'` instead of `approved` to reject a staff application.
The user can then correct their number and submit again. Only project
administrators should run review queries; the app does not expose identity
records to clients.

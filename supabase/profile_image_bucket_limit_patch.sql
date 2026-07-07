-- Run this once in the Supabase SQL Editor for existing installations.
-- It raises the private profile image bucket limit from 5 MB to 15 MB.

update storage.buckets
set
  file_size_limit = 15728640,
  allowed_mime_types = array['image/jpeg', 'image/png']
where id = 'profile-images';

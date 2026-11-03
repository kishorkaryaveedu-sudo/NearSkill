-- Enable realtime for tables
begin;
  -- remove the supabase_realtime publication if it exists
  drop publication if exists supabase_realtime;
  -- re-create the publication
  create publication supabase_realtime;
commit;
alter publication supabase_realtime add table chat_messages, service_requests, worker_profiles;

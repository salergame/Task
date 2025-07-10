-- Создание таблицы для обращений в поддержку
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, in_progress, resolved, closed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  operator_response TEXT,
  responded_at TIMESTAMP WITH TIME ZONE,
  estimated_response_time INTEGER DEFAULT 30,
  
  CONSTRAINT status_check CHECK (status IN ('pending', 'in_progress', 'resolved', 'closed'))
);

-- Создание таблицы для сообщений обращений
CREATE TABLE support_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  is_from_support BOOLEAN DEFAULT FALSE
);

-- Создание таблицы для файлов обращений
CREATE TABLE support_files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Создание политик доступа для таблицы support_tickets
CREATE POLICY "Users can view their own tickets" 
  ON support_tickets 
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own tickets" 
  ON support_tickets 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tickets" 
  ON support_tickets 
  FOR UPDATE 
  USING (auth.uid() = user_id);

-- Создание политик доступа для таблицы support_messages
CREATE POLICY "Users can view messages for their tickets" 
  ON support_messages 
  FOR SELECT 
  USING (
    auth.uid() = user_id OR 
    auth.uid() = (SELECT user_id FROM support_tickets WHERE id = ticket_id)
  );

CREATE POLICY "Users can create messages for their tickets" 
  ON support_messages 
  FOR INSERT 
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (SELECT 1 FROM support_tickets WHERE id = ticket_id AND user_id = auth.uid())
  );

-- Создание политик доступа для таблицы support_files
CREATE POLICY "Users can view files for their tickets" 
  ON support_files 
  FOR SELECT 
  USING (
    auth.uid() = user_id OR 
    auth.uid() = (SELECT user_id FROM support_tickets WHERE id = ticket_id)
  );

CREATE POLICY "Users can upload files for their tickets" 
  ON support_files 
  FOR INSERT 
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (SELECT 1 FROM support_tickets WHERE id = ticket_id AND user_id = auth.uid())
  );

-- Включение RLS (Row Level Security) для всех таблиц
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_files ENABLE ROW LEVEL SECURITY;

-- Создание бакета для хранения файлов обращений
-- Примечание: эту команду нужно выполнить через интерфейс Supabase или API
-- INSERT INTO storage.buckets (id, name) VALUES ('support_files', 'support_files');

-- Создание политики доступа к файлам в бакете
-- Примечание: эту команду нужно выполнить через интерфейс Supabase или API
-- CREATE POLICY "Users can upload files to support_files bucket"
--   ON storage.objects
--   FOR INSERT
--   WITH CHECK (bucket_id = 'support_files' AND auth.uid() = owner);

-- CREATE POLICY "Users can view files from support_files bucket"
--   ON storage.objects
--   FOR SELECT
--   USING (bucket_id = 'support_files'); 
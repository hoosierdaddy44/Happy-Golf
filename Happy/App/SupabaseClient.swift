import Supabase
import Foundation

// MARK: - Supabase Client
// Replace placeholder values with your project's URL and anon key from
// https://supabase.com/dashboard/project/<your-project>/settings/api

let supabase = SupabaseClient(
    supabaseURL: URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://pjuyeldemhghpdnyiury.supabase.co")!,
    supabaseKey: ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqdXllbGRlbWhnaHBkbnlpdXJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4NTI2ODYsImV4cCI6MjA5MTQyODY4Nn0.MjuytngVKJL1d1RHuxPvm8QlCvF5C5qTB2qPoiCD420"
    
)

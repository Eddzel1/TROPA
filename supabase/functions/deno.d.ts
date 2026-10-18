// Ambient declarations for Deno and Supabase Edge Functions in standard TypeScript IDE environments.
// When running in Supabase Edge Runtime, Deno provides these natively.

declare namespace Deno {
  export interface Env {
    get(key: string): string | undefined;
    set(key: string, value: string): void;
    delete(key: string): void;
    toObject(): Record<string, string>;
  }
  export const env: Env;
  export function serve(
    handler: (req: Request) => Response | Promise<Response>,
  ): void;
  export function serve(
    options: { port?: number; onListen?: (params: { port: number; hostname: string }) => void },
    handler: (req: Request) => Response | Promise<Response>,
  ): void;
}

declare module "npm:@supabase/supabase-js@2.45.4" {
  export interface User {
    id: string;
    email?: string;
    [key: string]: any;
  }

  export interface AdminAuthClient {
    createUser(attributes: any): Promise<{ data: { user: User | null }; error: any }>;
    deleteUser(id: string): Promise<{ data: any; error: any }>;
    updateUserById(id: string, attributes: any): Promise<{ data: { user: User | null }; error: any }>;
    [key: string]: any;
  }

  export interface GoTrueClient {
    admin: AdminAuthClient;
    getUser(jwt?: string): Promise<{ data: { user: User | null }; error: any }>;
    [key: string]: any;
  }

  export interface PostgrestFilterBuilder<T = any> {
    select(columns?: string): this;
    insert(values: any): this;
    update(values: any): this;
    delete(): this;
    eq(column: string, value: any): this;
    maybeSingle(): Promise<{ data: any; error: any }>;
    single(): Promise<{ data: any; error: any }>;
    [key: string]: any;
  }

  export interface SupabaseClient {
    auth: GoTrueClient;
    from(table: string): PostgrestFilterBuilder;
    [key: string]: any;
  }

  export interface SupabaseClientOptions<SchemaName> {
    auth?: {
      autoRefreshToken?: boolean;
      persistSession?: boolean;
      detectSessionInUrl?: boolean;
    };
    db?: {
      schema?: SchemaName;
    };
    global?: {
      headers?: Record<string, string>;
    };
  }

  export function createClient(
    supabaseUrl: string,
    supabaseKey: string,
    options?: SupabaseClientOptions<any>,
  ): SupabaseClient;
}

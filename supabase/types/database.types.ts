export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      ai_requests: {
        Row: {
          created_at: string
          id: number
          input_tokens: number | null
          kind: string
          latency_ms: number | null
          model: string
          ok: boolean
          output_tokens: number | null
          user_id: string | null
        }
        Insert: {
          created_at?: string
          id?: never
          input_tokens?: number | null
          kind: string
          latency_ms?: number | null
          model: string
          ok?: boolean
          output_tokens?: number | null
          user_id?: string | null
        }
        Update: {
          created_at?: string
          id?: never
          input_tokens?: number | null
          kind?: string
          latency_ms?: number | null
          model?: string
          ok?: boolean
          output_tokens?: number | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ai_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      app_config: {
        Row: {
          key: string
          updated_at: string
          value: Json
        }
        Insert: {
          key: string
          updated_at?: string
          value: Json
        }
        Update: {
          key?: string
          updated_at?: string
          value?: Json
        }
        Relationships: []
      }
      badges: {
        Row: {
          description: string
          icon: string
          key: string
          name: string
        }
        Insert: {
          description: string
          icon?: string
          key: string
          name: string
        }
        Update: {
          description?: string
          icon?: string
          key?: string
          name?: string
        }
        Relationships: []
      }
      blocks: {
        Row: {
          blocked_id: string
          blocker_id: string
          created_at: string
        }
        Insert: {
          blocked_id: string
          blocker_id: string
          created_at?: string
        }
        Update: {
          blocked_id?: string
          blocker_id?: string
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "blocks_blocked_id_fkey"
            columns: ["blocked_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "blocks_blocker_id_fkey"
            columns: ["blocker_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      comments: {
        Row: {
          body: string
          created_at: string
          deleted_at: string | null
          edited_at: string | null
          id: string
          meal_id: string
          parent_id: string | null
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          deleted_at?: string | null
          edited_at?: string | null
          id?: string
          meal_id: string
          parent_id?: string | null
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          deleted_at?: string | null
          edited_at?: string | null
          id?: string
          meal_id?: string
          parent_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comments_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      comparisons: {
        Row: {
          created_at: string
          id: number
          is_tie: boolean
          loser_place_id: string
          meal_id: string | null
          source: Database["public"]["Enums"]["comparison_source"]
          user_id: string
          winner_place_id: string
        }
        Insert: {
          created_at?: string
          id?: never
          is_tie?: boolean
          loser_place_id: string
          meal_id?: string | null
          source: Database["public"]["Enums"]["comparison_source"]
          user_id: string
          winner_place_id: string
        }
        Update: {
          created_at?: string
          id?: never
          is_tie?: boolean
          loser_place_id?: string
          meal_id?: string | null
          source?: Database["public"]["Enums"]["comparison_source"]
          user_id?: string
          winner_place_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comparisons_loser_place_id_fkey"
            columns: ["loser_place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comparisons_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comparisons_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comparisons_winner_place_id_fkey"
            columns: ["winner_place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      crew_members: {
        Row: {
          crew_id: string
          joined_at: string
          role: string
          user_id: string
        }
        Insert: {
          crew_id: string
          joined_at?: string
          role?: string
          user_id: string
        }
        Update: {
          crew_id?: string
          joined_at?: string
          role?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "crew_members_crew_id_fkey"
            columns: ["crew_id"]
            isOneToOne: false
            referencedRelation: "crews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crew_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      crews: {
        Row: {
          created_at: string
          id: string
          name: string
          owner_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          owner_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          owner_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "crews_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      decide_candidates: {
        Row: {
          group_score: number | null
          place_id: string
          position: number
          reason: string | null
          session_id: string
        }
        Insert: {
          group_score?: number | null
          place_id: string
          position: number
          reason?: string | null
          session_id: string
        }
        Update: {
          group_score?: number | null
          place_id?: string
          position?: number
          reason?: string | null
          session_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "decide_candidates_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "decide_candidates_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "decide_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      decide_participants: {
        Row: {
          guest_name: string | null
          guest_token: string | null
          id: string
          joined_at: string
          session_id: string
          user_id: string | null
        }
        Insert: {
          guest_name?: string | null
          guest_token?: string | null
          id?: string
          joined_at?: string
          session_id: string
          user_id?: string | null
        }
        Update: {
          guest_name?: string | null
          guest_token?: string | null
          id?: string
          joined_at?: string
          session_id?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "decide_participants_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "decide_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "decide_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      decide_sessions: {
        Row: {
          center: unknown
          constraints: Json
          created_at: string
          crew_id: string | null
          decided_at: string | null
          expires_at: string
          host_id: string
          id: string
          invite_code: string
          matched_place_id: string | null
          status: Database["public"]["Enums"]["decide_status"]
        }
        Insert: {
          center?: unknown
          constraints?: Json
          created_at?: string
          crew_id?: string | null
          decided_at?: string | null
          expires_at?: string
          host_id: string
          id?: string
          invite_code?: string
          matched_place_id?: string | null
          status?: Database["public"]["Enums"]["decide_status"]
        }
        Update: {
          center?: unknown
          constraints?: Json
          created_at?: string
          crew_id?: string | null
          decided_at?: string | null
          expires_at?: string
          host_id?: string
          id?: string
          invite_code?: string
          matched_place_id?: string | null
          status?: Database["public"]["Enums"]["decide_status"]
        }
        Relationships: [
          {
            foreignKeyName: "decide_sessions_crew_id_fkey"
            columns: ["crew_id"]
            isOneToOne: false
            referencedRelation: "crews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "decide_sessions_host_id_fkey"
            columns: ["host_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "decide_sessions_matched_place_id_fkey"
            columns: ["matched_place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      decide_votes: {
        Row: {
          created_at: string
          liked: boolean
          participant_id: string
          place_id: string
          session_id: string
        }
        Insert: {
          created_at?: string
          liked: boolean
          participant_id: string
          place_id: string
          session_id: string
        }
        Update: {
          created_at?: string
          liked?: boolean
          participant_id?: string
          place_id?: string
          session_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "decide_votes_participant_id_fkey"
            columns: ["participant_id"]
            isOneToOne: false
            referencedRelation: "decide_participants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "decide_votes_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "decide_votes_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "decide_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      device_tokens: {
        Row: {
          app_version: string | null
          created_at: string
          id: string
          kind: string
          token: string
          updated_at: string
          user_id: string
        }
        Insert: {
          app_version?: string | null
          created_at?: string
          id?: string
          kind: string
          token: string
          updated_at?: string
          user_id: string
        }
        Update: {
          app_version?: string | null
          created_at?: string
          id?: string
          kind?: string
          token?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "device_tokens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      dish_ratings: {
        Row: {
          created_at: string
          dish_id: string
          is_best: boolean
          meal_id: string
          thumb: number
          user_id: string
        }
        Insert: {
          created_at?: string
          dish_id: string
          is_best?: boolean
          meal_id: string
          thumb: number
          user_id: string
        }
        Update: {
          created_at?: string
          dish_id?: string
          is_best?: boolean
          meal_id?: string
          thumb?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "dish_ratings_dish_id_fkey"
            columns: ["dish_id"]
            isOneToOne: false
            referencedRelation: "dishes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dish_ratings_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dish_ratings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      dishes: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          name: string
          name_key: string | null
          place_id: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          name: string
          name_key?: string | null
          place_id: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          name?: string
          name_key?: string | null
          place_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "dishes_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dishes_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      fight_matchups: {
        Row: {
          closes_at: string
          fight_id: string
          id: string
          opens_at: string
          place_a: string
          place_b: string
          round: number
          slot: number
          winner_place_id: string | null
        }
        Insert: {
          closes_at: string
          fight_id: string
          id?: string
          opens_at: string
          place_a: string
          place_b: string
          round: number
          slot: number
          winner_place_id?: string | null
        }
        Update: {
          closes_at?: string
          fight_id?: string
          id?: string
          opens_at?: string
          place_a?: string
          place_b?: string
          round?: number
          slot?: number
          winner_place_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fight_matchups_fight_id_fkey"
            columns: ["fight_id"]
            isOneToOne: false
            referencedRelation: "food_fights"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fight_matchups_place_a_fkey"
            columns: ["place_a"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fight_matchups_place_b_fkey"
            columns: ["place_b"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fight_matchups_winner_place_id_fkey"
            columns: ["winner_place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      fight_votes: {
        Row: {
          created_at: string
          matchup_id: string
          user_id: string
          winner_place_id: string
        }
        Insert: {
          created_at?: string
          matchup_id: string
          user_id: string
          winner_place_id: string
        }
        Update: {
          created_at?: string
          matchup_id?: string
          user_id?: string
          winner_place_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fight_votes_matchup_id_fkey"
            columns: ["matchup_id"]
            isOneToOne: false
            referencedRelation: "fight_matchups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fight_votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fight_votes_winner_place_id_fkey"
            columns: ["winner_place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      follows: {
        Row: {
          accepted_at: string | null
          created_at: string
          followee_id: string
          follower_id: string
          status: Database["public"]["Enums"]["follow_status"]
        }
        Insert: {
          accepted_at?: string | null
          created_at?: string
          followee_id: string
          follower_id: string
          status?: Database["public"]["Enums"]["follow_status"]
        }
        Update: {
          accepted_at?: string | null
          created_at?: string
          followee_id?: string
          follower_id?: string
          status?: Database["public"]["Enums"]["follow_status"]
        }
        Relationships: [
          {
            foreignKeyName: "follows_followee_id_fkey"
            columns: ["followee_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "follows_follower_id_fkey"
            columns: ["follower_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      food_fights: {
        Row: {
          created_at: string
          cuisine: string | null
          ends_at: string
          id: string
          school_id: string
          starts_at: string
          status: string
          title: string
          vibe: Database["public"]["Enums"]["vibe"] | null
          winner_place_id: string | null
        }
        Insert: {
          created_at?: string
          cuisine?: string | null
          ends_at: string
          id?: string
          school_id: string
          starts_at: string
          status?: string
          title: string
          vibe?: Database["public"]["Enums"]["vibe"] | null
          winner_place_id?: string | null
        }
        Update: {
          created_at?: string
          cuisine?: string | null
          ends_at?: string
          id?: string
          school_id?: string
          starts_at?: string
          status?: string
          title?: string
          vibe?: Database["public"]["Enums"]["vibe"] | null
          winner_place_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "food_fights_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "food_fights_winner_place_id_fkey"
            columns: ["winner_place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      meal_media: {
        Row: {
          back_path: string | null
          caption: string | null
          created_at: string
          dish_id: string | null
          front_path: string | null
          height: number | null
          id: string
          is_live: boolean
          kind: Database["public"]["Enums"]["media_kind"]
          meal_id: string
          moment: Database["public"]["Enums"]["moment"]
          sort_order: number
          taken_at: string
          thumb_path: string | null
          user_id: string
          video_path: string | null
          width: number | null
        }
        Insert: {
          back_path?: string | null
          caption?: string | null
          created_at?: string
          dish_id?: string | null
          front_path?: string | null
          height?: number | null
          id?: string
          is_live?: boolean
          kind?: Database["public"]["Enums"]["media_kind"]
          meal_id: string
          moment?: Database["public"]["Enums"]["moment"]
          sort_order?: number
          taken_at?: string
          thumb_path?: string | null
          user_id: string
          video_path?: string | null
          width?: number | null
        }
        Update: {
          back_path?: string | null
          caption?: string | null
          created_at?: string
          dish_id?: string | null
          front_path?: string | null
          height?: number | null
          id?: string
          is_live?: boolean
          kind?: Database["public"]["Enums"]["media_kind"]
          meal_id?: string
          moment?: Database["public"]["Enums"]["moment"]
          sort_order?: number
          taken_at?: string
          thumb_path?: string | null
          user_id?: string
          video_path?: string | null
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "meal_media_dish_id_fkey"
            columns: ["dish_id"]
            isOneToOne: false
            referencedRelation: "dishes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_media_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_media_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      meals: {
        Row: {
          cover_media_id: string | null
          created_at: string
          currency: string
          ended_at: string | null
          id: string
          note: string | null
          party_id: string | null
          place_id: string
          plan_id: string | null
          posted_at: string | null
          price_per_person: number | null
          score_at_post: number | null
          started_at: string
          status: Database["public"]["Enums"]["meal_status"]
          tier: Database["public"]["Enums"]["tier"] | null
          updated_at: string
          user_id: string
          vibe: Database["public"]["Enums"]["vibe"] | null
          visibility: Database["public"]["Enums"]["meal_visibility"]
          visit_delta: string | null
        }
        Insert: {
          cover_media_id?: string | null
          created_at?: string
          currency?: string
          ended_at?: string | null
          id?: string
          note?: string | null
          party_id?: string | null
          place_id: string
          plan_id?: string | null
          posted_at?: string | null
          price_per_person?: number | null
          score_at_post?: number | null
          started_at?: string
          status?: Database["public"]["Enums"]["meal_status"]
          tier?: Database["public"]["Enums"]["tier"] | null
          updated_at?: string
          user_id: string
          vibe?: Database["public"]["Enums"]["vibe"] | null
          visibility?: Database["public"]["Enums"]["meal_visibility"]
          visit_delta?: string | null
        }
        Update: {
          cover_media_id?: string | null
          created_at?: string
          currency?: string
          ended_at?: string | null
          id?: string
          note?: string | null
          party_id?: string | null
          place_id?: string
          plan_id?: string | null
          posted_at?: string | null
          price_per_person?: number | null
          score_at_post?: number | null
          started_at?: string
          status?: Database["public"]["Enums"]["meal_status"]
          tier?: Database["public"]["Enums"]["tier"] | null
          updated_at?: string
          user_id?: string
          vibe?: Database["public"]["Enums"]["vibe"] | null
          visibility?: Database["public"]["Enums"]["meal_visibility"]
          visit_delta?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "meals_cover_media_fk"
            columns: ["cover_media_id"]
            isOneToOne: false
            referencedRelation: "meal_media"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meals_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meals_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meals_plan_fk"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meals_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          actor_id: string | null
          created_at: string
          id: string
          kind: string
          meal_id: string | null
          payload: Json
          place_id: string | null
          plan_id: string | null
          pushed_at: string | null
          read_at: string | null
          user_id: string
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          id?: string
          kind: string
          meal_id?: string | null
          payload?: Json
          place_id?: string | null
          plan_id?: string | null
          pushed_at?: string | null
          read_at?: string | null
          user_id: string
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          id?: string
          kind?: string
          meal_id?: string | null
          payload?: Json
          place_id?: string | null
          plan_id?: string | null
          pushed_at?: string | null
          read_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      parties: {
        Row: {
          created_at: string
          ended_at: string | null
          host_id: string
          id: string
          join_code: string
          place_id: string
          plan_id: string | null
        }
        Insert: {
          created_at?: string
          ended_at?: string | null
          host_id: string
          id?: string
          join_code?: string
          place_id: string
          plan_id?: string | null
        }
        Update: {
          created_at?: string
          ended_at?: string | null
          host_id?: string
          id?: string
          join_code?: string
          place_id?: string
          plan_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "parties_host_id_fkey"
            columns: ["host_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_plan_fk"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "plans"
            referencedColumns: ["id"]
          },
        ]
      }
      party_members: {
        Row: {
          created_at: string
          invited_by: string | null
          meal_id: string | null
          party_id: string
          responded_at: string | null
          status: Database["public"]["Enums"]["member_status"]
          user_id: string
        }
        Insert: {
          created_at?: string
          invited_by?: string | null
          meal_id?: string | null
          party_id: string
          responded_at?: string | null
          status?: Database["public"]["Enums"]["member_status"]
          user_id: string
        }
        Update: {
          created_at?: string
          invited_by?: string | null
          meal_id?: string | null
          party_id?: string
          responded_at?: string | null
          status?: Database["public"]["Enums"]["member_status"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "party_members_invited_by_fkey"
            columns: ["invited_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_members_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_members_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      place_edits: {
        Row: {
          created_at: string
          field: string
          id: string
          note: string | null
          place_id: string
          reviewed_at: string | null
          status: Database["public"]["Enums"]["edit_status"]
          user_id: string
          value: Json
        }
        Insert: {
          created_at?: string
          field: string
          id?: string
          note?: string | null
          place_id: string
          reviewed_at?: string | null
          status?: Database["public"]["Enums"]["edit_status"]
          user_id: string
          value: Json
        }
        Update: {
          created_at?: string
          field?: string
          id?: string
          note?: string | null
          place_id?: string
          reviewed_at?: string | null
          status?: Database["public"]["Enums"]["edit_status"]
          user_id?: string
          value?: Json
        }
        Relationships: [
          {
            foreignKeyName: "place_edits_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "place_edits_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      place_hours: {
        Row: {
          closes: string
          dow: number
          opens: string
          place_id: string
          source: string
          updated_at: string
        }
        Insert: {
          closes: string
          dow: number
          opens: string
          place_id: string
          source?: string
          updated_at?: string
        }
        Update: {
          closes?: string
          dow?: number
          opens?: string
          place_id?: string
          source?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "place_hours_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      place_import: {
        Row: {
          address: string | null
          categories: string[]
          confidence: number | null
          country: string | null
          imported_at: string
          locality: string | null
          location: unknown
          matched_place_id: string | null
          name: string
          name_key: string | null
          phone: string | null
          postcode: string | null
          raw: Json | null
          region: string | null
          source: Database["public"]["Enums"]["place_source"]
          source_id: string
          website: string | null
        }
        Insert: {
          address?: string | null
          categories?: string[]
          confidence?: number | null
          country?: string | null
          imported_at?: string
          locality?: string | null
          location: unknown
          matched_place_id?: string | null
          name: string
          name_key?: string | null
          phone?: string | null
          postcode?: string | null
          raw?: Json | null
          region?: string | null
          source: Database["public"]["Enums"]["place_source"]
          source_id: string
          website?: string | null
        }
        Update: {
          address?: string | null
          categories?: string[]
          confidence?: number | null
          country?: string | null
          imported_at?: string
          locality?: string | null
          location?: unknown
          matched_place_id?: string | null
          name?: string
          name_key?: string | null
          phone?: string | null
          postcode?: string | null
          raw?: Json | null
          region?: string | null
          source?: Database["public"]["Enums"]["place_source"]
          source_id?: string
          website?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "place_import_matched_place_id_fkey"
            columns: ["matched_place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      place_stats: {
        Row: {
          bayes_score: number | null
          mean_score: number | null
          n_loved: number
          n_meals_7d: number
          n_ratings: number
          n_saves: number
          place_id: string
          school_id: string
          trending_score: number
          updated_at: string
        }
        Insert: {
          bayes_score?: number | null
          mean_score?: number | null
          n_loved?: number
          n_meals_7d?: number
          n_ratings?: number
          n_saves?: number
          place_id: string
          school_id: string
          trending_score?: number
          updated_at?: string
        }
        Update: {
          bayes_score?: number | null
          mean_score?: number | null
          n_loved?: number
          n_meals_7d?: number
          n_ratings?: number
          n_saves?: number
          place_id?: string
          school_id?: string
          trending_score?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "place_stats_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "place_stats_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      places: {
        Row: {
          address: string | null
          apple_place_id: string | null
          country: string
          created_at: string
          created_by: string | null
          cuisines: string[]
          fsq_place_id: string | null
          google_place_id: string | null
          id: string
          is_permanently_closed: boolean
          locality: string | null
          location: unknown
          menu_url: string | null
          name: string
          name_key: string | null
          neighborhood: string | null
          osm_id: string | null
          overture_id: string | null
          phone: string | null
          postcode: string | null
          price_level: number | null
          primary_category: string | null
          region: string | null
          reservation_provider: Database["public"]["Enums"]["reservation_provider"]
          reservation_url: string | null
          source: Database["public"]["Enums"]["place_source"]
          tags: string[]
          timezone: string | null
          updated_at: string
          website: string | null
          yelp_business_id: string | null
        }
        Insert: {
          address?: string | null
          apple_place_id?: string | null
          country?: string
          created_at?: string
          created_by?: string | null
          cuisines?: string[]
          fsq_place_id?: string | null
          google_place_id?: string | null
          id?: string
          is_permanently_closed?: boolean
          locality?: string | null
          location: unknown
          menu_url?: string | null
          name: string
          name_key?: string | null
          neighborhood?: string | null
          osm_id?: string | null
          overture_id?: string | null
          phone?: string | null
          postcode?: string | null
          price_level?: number | null
          primary_category?: string | null
          region?: string | null
          reservation_provider?: Database["public"]["Enums"]["reservation_provider"]
          reservation_url?: string | null
          source: Database["public"]["Enums"]["place_source"]
          tags?: string[]
          timezone?: string | null
          updated_at?: string
          website?: string | null
          yelp_business_id?: string | null
        }
        Update: {
          address?: string | null
          apple_place_id?: string | null
          country?: string
          created_at?: string
          created_by?: string | null
          cuisines?: string[]
          fsq_place_id?: string | null
          google_place_id?: string | null
          id?: string
          is_permanently_closed?: boolean
          locality?: string | null
          location?: unknown
          menu_url?: string | null
          name?: string
          name_key?: string | null
          neighborhood?: string | null
          osm_id?: string | null
          overture_id?: string | null
          phone?: string | null
          postcode?: string | null
          price_level?: number | null
          primary_category?: string | null
          region?: string | null
          reservation_provider?: Database["public"]["Enums"]["reservation_provider"]
          reservation_url?: string | null
          source?: Database["public"]["Enums"]["place_source"]
          tags?: string[]
          timezone?: string | null
          updated_at?: string
          website?: string | null
          yelp_business_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "places_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      plan_guests: {
        Row: {
          created_at: string
          guest_name: string | null
          guest_token: string | null
          id: string
          invited_by: string | null
          plan_id: string
          responded_at: string | null
          rsvp: Database["public"]["Enums"]["rsvp"]
          user_id: string | null
        }
        Insert: {
          created_at?: string
          guest_name?: string | null
          guest_token?: string | null
          id?: string
          invited_by?: string | null
          plan_id: string
          responded_at?: string | null
          rsvp?: Database["public"]["Enums"]["rsvp"]
          user_id?: string | null
        }
        Update: {
          created_at?: string
          guest_name?: string | null
          guest_token?: string | null
          id?: string
          invited_by?: string | null
          plan_id?: string
          responded_at?: string | null
          rsvp?: Database["public"]["Enums"]["rsvp"]
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "plan_guests_invited_by_fkey"
            columns: ["invited_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plan_guests_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plan_guests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      plans: {
        Row: {
          created_at: string
          crew_id: string | null
          decide_session_id: string | null
          host_id: string
          id: string
          invite_code: string
          note: string | null
          party_size: number | null
          place_id: string
          reservation_ref: string | null
          reservation_status: Database["public"]["Enums"]["reservation_status"]
          starts_at: string
          status: Database["public"]["Enums"]["plan_status"]
          title: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          crew_id?: string | null
          decide_session_id?: string | null
          host_id: string
          id?: string
          invite_code?: string
          note?: string | null
          party_size?: number | null
          place_id: string
          reservation_ref?: string | null
          reservation_status?: Database["public"]["Enums"]["reservation_status"]
          starts_at: string
          status?: Database["public"]["Enums"]["plan_status"]
          title?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          crew_id?: string | null
          decide_session_id?: string | null
          host_id?: string
          id?: string
          invite_code?: string
          note?: string | null
          party_size?: number | null
          place_id?: string
          reservation_ref?: string | null
          reservation_status?: Database["public"]["Enums"]["reservation_status"]
          starts_at?: string
          status?: Database["public"]["Enums"]["plan_status"]
          title?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "plans_crew_id_fkey"
            columns: ["crew_id"]
            isOneToOne: false
            referencedRelation: "crews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plans_decide_session_id_fkey"
            columns: ["decide_session_id"]
            isOneToOne: false
            referencedRelation: "decide_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plans_host_id_fkey"
            columns: ["host_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plans_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_path: string | null
          bio: string | null
          created_at: string
          display_name: string
          handle: string
          id: string
          is_demo: boolean
          is_private: boolean
          notification_prefs: Json
          onboarded_at: string | null
          school_id: string | null
          terms_accepted_at: string | null
          terms_version: string | null
          updated_at: string
        }
        Insert: {
          avatar_path?: string | null
          bio?: string | null
          created_at?: string
          display_name: string
          handle: string
          id: string
          is_demo?: boolean
          is_private?: boolean
          notification_prefs?: Json
          onboarded_at?: string | null
          school_id?: string | null
          terms_accepted_at?: string | null
          terms_version?: string | null
          updated_at?: string
        }
        Update: {
          avatar_path?: string | null
          bio?: string | null
          created_at?: string
          display_name?: string
          handle?: string
          id?: string
          is_demo?: boolean
          is_private?: boolean
          notification_prefs?: Json
          onboarded_at?: string | null
          school_id?: string | null
          terms_accepted_at?: string | null
          terms_version?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      quick_takes: {
        Row: {
          audio_path: string | null
          body: string | null
          created_at: string
          id: string
          meal_id: string
          transcript: string | null
          user_id: string
        }
        Insert: {
          audio_path?: string | null
          body?: string | null
          created_at?: string
          id?: string
          meal_id: string
          transcript?: string | null
          user_id: string
        }
        Update: {
          audio_path?: string | null
          body?: string | null
          created_at?: string
          id?: string
          meal_id?: string
          transcript?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quick_takes_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quick_takes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      rankings: {
        Row: {
          created_at: string
          last_meal_id: string | null
          place_id: string
          position: number
          score: number
          settled: boolean
          tier: Database["public"]["Enums"]["tier"]
          updated_at: string
          user_id: string
          vibe: Database["public"]["Enums"]["vibe"]
          visits: number
        }
        Insert: {
          created_at?: string
          last_meal_id?: string | null
          place_id: string
          position: number
          score?: number
          settled?: boolean
          tier: Database["public"]["Enums"]["tier"]
          updated_at?: string
          user_id: string
          vibe: Database["public"]["Enums"]["vibe"]
          visits?: number
        }
        Update: {
          created_at?: string
          last_meal_id?: string | null
          place_id?: string
          position?: number
          score?: number
          settled?: boolean
          tier?: Database["public"]["Enums"]["tier"]
          updated_at?: string
          user_id?: string
          vibe?: Database["public"]["Enums"]["vibe"]
          visits?: number
        }
        Relationships: [
          {
            foreignKeyName: "rankings_last_meal_id_fkey"
            columns: ["last_meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "rankings_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "rankings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reactions: {
        Row: {
          created_at: string
          kind: string
          meal_id: string
          selfie_path: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          kind: string
          meal_id: string
          selfie_path?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          kind?: string
          meal_id?: string
          selfie_path?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "reactions_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reports: {
        Row: {
          created_at: string
          details: string | null
          id: string
          reason: string
          reporter_id: string
          resolved_at: string | null
          status: Database["public"]["Enums"]["report_status"]
          target_id: string
          target_type: string
        }
        Insert: {
          created_at?: string
          details?: string | null
          id?: string
          reason: string
          reporter_id: string
          resolved_at?: string | null
          status?: Database["public"]["Enums"]["report_status"]
          target_id: string
          target_type: string
        }
        Update: {
          created_at?: string
          details?: string | null
          id?: string
          reason?: string
          reporter_id?: string
          resolved_at?: string | null
          status?: Database["public"]["Enums"]["report_status"]
          target_id?: string
          target_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      saves: {
        Row: {
          created_at: string
          note: string | null
          place_id: string
          source_meal_id: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          note?: string | null
          place_id: string
          source_meal_id?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          note?: string | null
          place_id?: string
          source_meal_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "saves_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "saves_source_meal_fk"
            columns: ["source_meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "saves_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      schools: {
        Row: {
          center: unknown
          city: string
          created_at: string
          email_domains: string[]
          id: string
          is_live: boolean
          name: string
          short_name: string
          slug: string
          timezone: string
        }
        Insert: {
          center?: unknown
          city: string
          created_at?: string
          email_domains?: string[]
          id?: string
          is_live?: boolean
          name: string
          short_name: string
          slug: string
          timezone?: string
        }
        Update: {
          center?: unknown
          city?: string
          created_at?: string
          email_domains?: string[]
          id?: string
          is_live?: boolean
          name?: string
          short_name?: string
          slug?: string
          timezone?: string
        }
        Relationships: []
      }
      seasons: {
        Row: {
          ends_on: string
          id: string
          name: string
          school_id: string
          starts_on: string
        }
        Insert: {
          ends_on: string
          id?: string
          name: string
          school_id: string
          starts_on: string
        }
        Update: {
          ends_on?: string
          id?: string
          name?: string
          school_id?: string
          starts_on?: string
        }
        Relationships: [
          {
            foreignKeyName: "seasons_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      signup_allowlist: {
        Row: {
          created_at: string
          email: string
          is_demo: boolean
          note: string | null
          school_id: string | null
        }
        Insert: {
          created_at?: string
          email: string
          is_demo?: boolean
          note?: string | null
          school_id?: string | null
        }
        Update: {
          created_at?: string
          email?: string
          is_demo?: boolean
          note?: string | null
          school_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "signup_allowlist_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      user_badges: {
        Row: {
          badge_key: string
          earned_at: string
          user_id: string
        }
        Insert: {
          badge_key: string
          earned_at?: string
          user_id: string
        }
        Update: {
          badge_key?: string
          earned_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_badges_badge_key_fkey"
            columns: ["badge_key"]
            isOneToOne: false
            referencedRelation: "badges"
            referencedColumns: ["key"]
          },
          {
            foreignKeyName: "user_badges_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_similarity: {
        Row: {
          corr: number
          n_shared: number
          updated_at: string
          user_a: string
          user_b: string
        }
        Insert: {
          corr: number
          n_shared: number
          updated_at?: string
          user_a: string
          user_b: string
        }
        Update: {
          corr?: number
          n_shared?: number
          updated_at?: string
          user_a?: string
          user_b?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_similarity_user_a_fkey"
            columns: ["user_a"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_similarity_user_b_fkey"
            columns: ["user_b"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      _close_stale_meals: { Args: never; Returns: number }
      _insert_ranking: {
        Args: {
          p_meal: string
          p_place: string
          p_position: number
          p_settled: boolean
          p_tier: Database["public"]["Enums"]["tier"]
          p_user: string
          p_vibe: Database["public"]["Enums"]["vibe"]
          p_visits?: number
        }
        Returns: number
      }
      _is_client: { Args: never; Returns: boolean }
      _notify: {
        Args: {
          p_actor?: string
          p_kind: string
          p_meal?: string
          p_payload?: Json
          p_place?: string
          p_plan?: string
          p_user: string
        }
        Returns: undefined
      }
      _recompute_tier_scores: {
        Args: { p_tier: Database["public"]["Enums"]["tier"]; p_user: string }
        Returns: undefined
      }
      _refresh_place_stats: { Args: never; Returns: undefined }
      _refresh_user_similarity: { Args: never; Returns: undefined }
      _remove_ranking: {
        Args: { p_place: string; p_user: string }
        Returns: Database["public"]["Enums"]["tier"]
      }
      _resolve_place_v1: {
        Args: {
          p_address?: string
          p_apple_place_id: string
          p_category?: string
          p_lat: number
          p_lng: number
          p_name: string
        }
        Returns: string
      }
      accept_terms: { Args: { p_terms_version: string }; Returns: undefined }
      can_view_meal: { Args: { p_meal: string }; Returns: boolean }
      can_view_plan: { Args: { p_plan: string }; Returns: boolean }
      can_view_user_content: { Args: { p_author: string }; Returns: boolean }
      complete_onboarding: {
        Args: {
          p_display_name: string
          p_handle: string
          p_terms_version: string
        }
        Returns: {
          avatar_path: string | null
          bio: string | null
          created_at: string
          display_name: string
          handle: string
          id: string
          is_demo: boolean
          is_private: boolean
          notification_prefs: Json
          onboarded_at: string | null
          school_id: string | null
          terms_accepted_at: string | null
          terms_version: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_decide_session: {
        Args: {
          p_constraints?: Json
          p_crew_id?: string
          p_lat: number
          p_lng: number
          p_member_ids: string[]
          p_size?: number
        }
        Returns: string
      }
      create_plan: {
        Args: {
          p_crew_id?: string
          p_decide_session_id?: string
          p_invitee_ids?: string[]
          p_note?: string
          p_place_id: string
          p_starts_at: string
        }
        Returns: {
          created_at: string
          crew_id: string | null
          decide_session_id: string | null
          host_id: string
          id: string
          invite_code: string
          note: string | null
          party_size: number | null
          place_id: string
          reservation_ref: string | null
          reservation_status: Database["public"]["Enums"]["reservation_status"]
          starts_at: string
          status: Database["public"]["Enums"]["plan_status"]
          title: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "plans"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      decide_finalize: { Args: { p_session_id: string }; Returns: string }
      decide_vote: {
        Args: { p_liked: boolean; p_place_id: string; p_session_id: string }
        Returns: string
      }
      fight_vote: {
        Args: { p_matchup_id: string; p_winner: string }
        Returns: undefined
      }
      get_feed: {
        Args: { p_before?: string; p_limit?: number }
        Returns: {
          cover_media_id: string | null
          created_at: string
          currency: string
          ended_at: string | null
          id: string
          note: string | null
          party_id: string | null
          place_id: string
          plan_id: string | null
          posted_at: string | null
          price_per_person: number | null
          score_at_post: number | null
          started_at: string
          status: Database["public"]["Enums"]["meal_status"]
          tier: Database["public"]["Enums"]["tier"] | null
          updated_at: string
          user_id: string
          vibe: Database["public"]["Enums"]["vibe"] | null
          visibility: Database["public"]["Enums"]["meal_visibility"]
          visit_delta: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "meals"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_place_meals: {
        Args: { p_before?: string; p_limit?: number; p_place_id: string }
        Returns: {
          cover_media_id: string | null
          created_at: string
          currency: string
          ended_at: string | null
          id: string
          note: string | null
          party_id: string | null
          place_id: string
          plan_id: string | null
          posted_at: string | null
          price_per_person: number | null
          score_at_post: number | null
          started_at: string
          status: Database["public"]["Enums"]["meal_status"]
          tier: Database["public"]["Enums"]["tier"] | null
          updated_at: string
          user_id: string
          vibe: Database["public"]["Enums"]["vibe"] | null
          visibility: Database["public"]["Enums"]["meal_visibility"]
          visit_delta: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "meals"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_place_scores: {
        Args: { p_place_id: string }
        Returns: {
          campus_count: number
          campus_score: number
          following_avg: number
          following_count: number
          friends_saved: number
          my_score: number
          my_tier: Database["public"]["Enums"]["tier"]
          my_vibe: Database["public"]["Enums"]["vibe"]
          open_now: boolean
          predicted: number
          saved: boolean
        }[]
      }
      hook_before_user_created: { Args: { event: Json }; Returns: Json }
      is_blocked_between: { Args: { a: string; b: string }; Returns: boolean }
      is_crew_member: {
        Args: { p_crew: string; p_user?: string }
        Returns: boolean
      }
      is_decide_participant: {
        Args: { p_session: string; p_user?: string }
        Returns: boolean
      }
      is_following: {
        Args: { p_followee: string; p_follower: string }
        Returns: boolean
      }
      is_handle_available: { Args: { p_handle: string }; Returns: boolean }
      is_open_at: {
        Args: { p_at?: string; p_place_id: string; p_tz?: string }
        Returns: boolean
      }
      is_party_member: {
        Args: { p_party: string; p_user?: string }
        Returns: boolean
      }
      join_party: { Args: { p_join_code: string }; Returns: string }
      leaderboard: {
        Args: { p_limit?: number; p_season_id: string }
        Returns: {
          display_name: string
          handle: string
          places: number
          rank: number
          user_id: string
        }[]
      }
      move_ranking: {
        Args: {
          p_place_id: string
          p_position: number
          p_tier: Database["public"]["Enums"]["tier"]
          p_vibe?: Database["public"]["Enums"]["vibe"]
        }
        Returns: number
      }
      nearby_places: {
        Args: {
          p_lat: number
          p_limit?: number
          p_lng: number
          p_radius_m?: number
        }
        Returns: {
          distance_m: number
          place_id: string
        }[]
      }
      plan_by_code: {
        Args: { p_code: string }
        Returns: {
          created_at: string
          crew_id: string | null
          decide_session_id: string | null
          host_id: string
          id: string
          invite_code: string
          note: string | null
          party_size: number | null
          place_id: string
          reservation_ref: string | null
          reservation_status: Database["public"]["Enums"]["reservation_status"]
          starts_at: string
          status: Database["public"]["Enums"]["plan_status"]
          title: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "plans"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      predicted_score: {
        Args: { p_place_id: string; p_user?: string }
        Returns: number
      }
      record_comparison: {
        Args: {
          p_loser: string
          p_source?: Database["public"]["Enums"]["comparison_source"]
          p_tie?: boolean
          p_winner: string
        }
        Returns: undefined
      }
      rerate_visit: {
        Args: { p_direction: string; p_meal_id: string }
        Returns: {
          score: number
          tier_position: number
        }[]
      }
      resolve_place: {
        Args: {
          p_address?: string
          p_apple_place_id: string
          p_category?: string
          p_country?: string
          p_lat: number
          p_lng: number
          p_name: string
          p_timezone?: string
        }
        Returns: string
      }
      respond_party_invite: {
        Args: { p_accept: boolean; p_party_id: string }
        Returns: string
      }
      rsvp: {
        Args: { p_plan_id: string; p_rsvp: Database["public"]["Enums"]["rsvp"] }
        Returns: undefined
      }
      search_key: { Args: { p: string }; Returns: string }
      search_places: {
        Args: {
          p_lat?: number
          p_limit?: number
          p_lng?: number
          p_query: string
        }
        Returns: {
          address: string
          distance_m: number
          name: string
          place_id: string
          similarity: number
        }[]
      }
      submit_rating: {
        Args: {
          p_comparisons?: Json
          p_meal_id: string
          p_position: number
          p_settled?: boolean
          p_tier: Database["public"]["Enums"]["tier"]
          p_vibe: Database["public"]["Enums"]["vibe"]
        }
        Returns: {
          score: number
          tier_count: number
          tier_position: number
          vibe_rank: number
        }[]
      }
      tag_friends: {
        Args: { p_meal_id: string; p_user_ids: string[] }
        Returns: string
      }
      taste_match: {
        Args: { p_other: string }
        Returns: {
          match_pct: number
          shared: number
        }[]
      }
      tier_band: {
        Args: { p: Database["public"]["Enums"]["tier"] }
        Returns: Record<string, unknown>
      }
      tier_score: {
        Args: { n: number; p: Database["public"]["Enums"]["tier"]; pos: number }
        Returns: number
      }
      tonight_picks: {
        Args: {
          p_craving?: string
          p_lat: number
          p_limit?: number
          p_lng: number
          p_max_price?: number
          p_novelty?: number
          p_radius_m?: number
          p_vibe?: Database["public"]["Enums"]["vibe"]
        }
        Returns: {
          been: boolean
          campus_score: number
          distance_m: number
          follow_loved: number
          name: string
          open_now: boolean
          place_id: string
          predicted: number
          rank_score: number
          saved: boolean
          top_friend_handle: string
          top_friend_score: number
          walk_minutes: number
        }[]
      }
      try_uuid: { Args: { p: string }; Returns: string }
      user_streak: { Args: { p_user?: string }; Returns: number }
    }
    Enums: {
      comparison_source: "rate" | "settle" | "defend" | "fight" | "reorder"
      decide_status: "open" | "matched" | "closed"
      edit_status: "pending" | "approved" | "rejected"
      follow_status: "accepted" | "requested"
      meal_status: "live" | "unrated" | "posted" | "archived"
      meal_visibility: "followers" | "only_me"
      media_kind: "dual" | "single" | "clip"
      member_status: "pending" | "accepted" | "declined"
      moment: "walk_in" | "order" | "food" | "crew" | "damage_report" | "other"
      place_source: "fsq" | "overture" | "osm" | "user" | "admin"
      plan_status: "planned" | "cancelled" | "done"
      report_status: "open" | "actioned" | "dismissed"
      reservation_provider:
        | "opentable"
        | "resy"
        | "tock"
        | "website"
        | "phone"
        | "walk_in"
        | "unknown"
      reservation_status: "none" | "link_opened" | "confirmed" | "cancelled"
      rsvp: "invited" | "going" | "maybe" | "cant"
      tier: "loved" | "good" | "mid" | "nah"
      vibe:
        | "cheap_eats"
        | "sit_down"
        | "date_night"
        | "late_night"
        | "cafe"
        | "dessert"
        | "drinks"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      comparison_source: ["rate", "settle", "defend", "fight", "reorder"],
      decide_status: ["open", "matched", "closed"],
      edit_status: ["pending", "approved", "rejected"],
      follow_status: ["accepted", "requested"],
      meal_status: ["live", "unrated", "posted", "archived"],
      meal_visibility: ["followers", "only_me"],
      media_kind: ["dual", "single", "clip"],
      member_status: ["pending", "accepted", "declined"],
      moment: ["walk_in", "order", "food", "crew", "damage_report", "other"],
      place_source: ["fsq", "overture", "osm", "user", "admin"],
      plan_status: ["planned", "cancelled", "done"],
      report_status: ["open", "actioned", "dismissed"],
      reservation_provider: [
        "opentable",
        "resy",
        "tock",
        "website",
        "phone",
        "walk_in",
        "unknown",
      ],
      reservation_status: ["none", "link_opened", "confirmed", "cancelled"],
      rsvp: ["invited", "going", "maybe", "cant"],
      tier: ["loved", "good", "mid", "nah"],
      vibe: [
        "cheap_eats",
        "sit_down",
        "date_night",
        "late_night",
        "cafe",
        "dessert",
        "drinks",
      ],
    },
  },
} as const

"""Initial schema — users and resumes tables.

Revision ID: 0001
Revises: —
Create Date: 2026-07-27
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID

# revision identifiers, used by Alembic.
revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()

    # ── user_role enum ────────────────────────────────────────────────────────
    # Create enum type before the users table that references it.
    # Use raw SQL with IF NOT EXISTS so the migration is idempotent — safe to
    # run even if DEBUG-mode create_all already created the type.
    conn.execute(
        sa.text("CREATE TYPE user_role AS ENUM ('guest', 'user', 'admin')")
        if not _enum_exists(conn, "user_role")
        else sa.text("SELECT 1")
    )

    # ── users ─────────────────────────────────────────────────────────────────
    if not _table_exists(conn, "users"):
        op.create_table(
            "users",
            sa.Column("id", UUID(as_uuid=True), primary_key=True, nullable=False),
            sa.Column("email", sa.String(320), nullable=False),
            sa.Column("hashed_password", sa.String(255), nullable=False),
            sa.Column("full_name", sa.String(120), nullable=False),
            # Use create_type=False — we already created/checked the enum above.
            sa.Column(
                "role",
                sa.Enum("guest", "user", "admin", name="user_role", create_type=False),
                nullable=False,
                server_default="user",
            ),
            sa.Column(
                "is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")
            ),
            sa.Column(
                "is_verified", sa.Boolean(), nullable=False, server_default=sa.text("false")
            ),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=False,
            ),
            sa.Column(
                "updated_at",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=False,
            ),
        )
        op.create_index("ix_users_email", "users", ["email"], unique=True)

    # ── resumes ───────────────────────────────────────────────────────────────
    if not _table_exists(conn, "resumes"):
        op.create_table(
            "resumes",
            sa.Column("id", UUID(as_uuid=True), primary_key=True, nullable=False),
            sa.Column(
                "user_id",
                UUID(as_uuid=True),
                sa.ForeignKey("users.id", ondelete="CASCADE"),
                nullable=False,
            ),
            # Meta
            sa.Column(
                "title",
                sa.String(150),
                nullable=False,
                server_default="Untitled Resume",
            ),
            sa.Column("template", sa.String(50), nullable=False, server_default="modern"),
            sa.Column(
                "theme_color", sa.String(20), nullable=False, server_default="#4A3AFF"
            ),
            sa.Column("font", sa.String(50), nullable=False, server_default="inter"),
            sa.Column(
                "is_primary",
                sa.Boolean(),
                nullable=False,
                server_default=sa.text("false"),
            ),
            # Singular content
            sa.Column("photo_url", sa.String(500), nullable=True),
            sa.Column("headline", sa.String(200), nullable=True),
            sa.Column("professional_summary", sa.Text(), nullable=True),
            sa.Column(
                "personal_info",
                JSONB(),
                nullable=False,
                server_default=sa.text("'{}'"),
            ),
            # Repeatable sections — JSONB arrays
            sa.Column(
                "experience", JSONB(), nullable=False, server_default=sa.text("'[]'")
            ),
            sa.Column(
                "projects", JSONB(), nullable=False, server_default=sa.text("'[]'")
            ),
            sa.Column(
                "education", JSONB(), nullable=False, server_default=sa.text("'[]'")
            ),
            sa.Column(
                "certifications", JSONB(), nullable=False, server_default=sa.text("'[]'")
            ),
            sa.Column(
                "achievements", JSONB(), nullable=False, server_default=sa.text("'[]'")
            ),
            sa.Column(
                "skills", JSONB(), nullable=False, server_default=sa.text("'[]'")
            ),
            sa.Column(
                "languages", JSONB(), nullable=False, server_default=sa.text("'[]'")
            ),
            sa.Column(
                "interests", JSONB(), nullable=False, server_default=sa.text("'[]'")
            ),
            sa.Column(
                "references", JSONB(), nullable=False, server_default=sa.text("'[]'")
            ),
            sa.Column(
                "links", JSONB(), nullable=False, server_default=sa.text("'[]'")
            ),
            sa.Column(
                "custom_sections",
                JSONB(),
                nullable=False,
                server_default=sa.text("'[]'"),
            ),
            # Layout state
            sa.Column(
                "section_order",
                JSONB(),
                nullable=False,
                server_default=sa.text(
                    '\'["personal_info","headline","summary","experience","projects",'
                    '"education","certifications","achievements","skills","languages",'
                    '"interests","references","links","custom_sections"]\''
                ),
            ),
            sa.Column(
                "hidden_sections",
                JSONB(),
                nullable=False,
                server_default=sa.text("'[]'"),
            ),
            # Timestamps
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=False,
            ),
            sa.Column(
                "updated_at",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=False,
            ),
        )
        op.create_index("ix_resumes_user_id", "resumes", ["user_id"])


def downgrade() -> None:
    conn = op.get_bind()

    if _table_exists(conn, "resumes"):
        op.drop_index("ix_resumes_user_id", table_name="resumes")
        op.drop_table("resumes")

    if _table_exists(conn, "users"):
        op.drop_index("ix_users_email", table_name="users")
        op.drop_table("users")

    # Drop the enum type last (after all referencing tables are gone).
    if _enum_exists(conn, "user_role"):
        conn.execute(sa.text("DROP TYPE user_role"))


# ── helpers ───────────────────────────────────────────────────────────────────

def _table_exists(conn, table_name: str) -> bool:
    result = conn.execute(
        sa.text(
            "SELECT EXISTS (SELECT 1 FROM information_schema.tables "
            "WHERE table_schema = 'public' AND table_name = :name)"
        ),
        {"name": table_name},
    )
    return result.scalar()


def _enum_exists(conn, enum_name: str) -> bool:
    result = conn.execute(
        sa.text(
            "SELECT EXISTS (SELECT 1 FROM pg_type WHERE typname = :name)"
        ),
        {"name": enum_name},
    )
    return result.scalar()

defmodule Legendary.Core.MixProject do
  use Mix.Project

  @version "4.3.2"

  def project do
    [
      app: :core,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],

      # Docs
      name: "Legendary",
      source_url: "https://gitlab.com/mythic-insight/legendary",
      homepage_url: "https://legendaryframework.org/",
      docs: [
        main: "overview",
        extra_section: "Getting Started",
        extras: extras(),
        groups_for_extras: groups_for_extras(),
        groups_for_modules: groups_for_modules(),
        assets: "guides/assets",
      ],

      # Hex
      description: """
      A PETAL-stack batteries-included boilerplate for making Phoenix apps
      without tedium.
      """,
      package: [
        name: "legendary_core",
        maintainers: ["Robert Prehn"],
        licenses: ["MIT"],
        links: %{"GitLab" => "https://gitlab.com/mythic-insight/legendary"}
      ]
    ]
  end

  defp extras do
    [
      "guides/overview.md",
      "guides/tutorial.md",
      # "guides/tutorial.md": [filename: "tutorial", title: "Tutorial"],
      "guides/features/admin.md",
      "guides/features/auth.md",
      "guides/features/background-jobs.md",
      "guides/features/content-management.md",
      "guides/features/devops-templates.md",
      "guides/features/end-to-end-testing.md",
      "guides/features/email.md",
      "guides/features/feature-flags.md",
      "guides/features/i18n.md",
      "guides/features/tasks-and-scripts.md",
      "guides/features/linters.md",
    ]
  end

  defp groups_for_extras do
    [
      Guides: ~r{guides/[^\.]+.md},
    ]
  end

  defp groups_for_modules do
    [
      "Auth": [
        Legendary.Auth,
        Legendary.AuthWeb,
        ~r{Legendary\.Auth(Web)?\..+},
        Legendary.CoreWeb.Router.PowExtensionRouter
      ],
      "Email": [
        Legendary.CoreEmail,
        Legendary.CoreMailer,
        Legendary.CoreWeb.EmailHelpers,
        Legendary.CoreWeb.CoreEmailView,
      ],
      "Internationalization": [
        Legendary.I18n
      ],
      "Mix Tasks": [
        Legendary.Mix,
      ],
      "View Helpers": [
        Legendary.CoreWeb.ErrorHelpers,
        Legendary.CoreWeb.Helpers,
      ],
      "Core Other": [
        Legendary.Core,
        Legendary.Core.MapUtils,
        Legendary.Core.Repo,
        Legendary.Core.SharedDBConnectionPool,
        Mix.Legendary,
      ],
      "Web Other": [
        Legendary.CoreWeb,
        Legendary.CoreWeb.Endpoint,
        Legendary.CoreWeb.ErrorView,
        Legendary.CoreWeb.Gettext,
        Legendary.CoreWeb.LayoutView,
        Legendary.CoreWeb.Router,
        Legendary.CoreWeb.Router.Helpers,
        Legendary.CoreWeb.Telemetry,
        Legendary.CoreWeb.UserSocket,
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Legendary.Core.Application, []},
      extra_applications: [:bamboo, :bamboo_smtp, :logger, :mnesia, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bamboo, "~> 1.5"},
      {:bamboo_smtp, "~> 3.0"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_cldr, "~> 2.23.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:ex_url, "~> 1.3.1"},
      {:excoveralls, "~> 0.10", only: [:dev, :test]},
      {:ex_aws, "~> 2.1.2"},
      {:ex_aws_s3, "~> 2.0"},
      {:fun_with_flags, "~> 1.6.0"},
      {:fun_with_flags_ui, "~> 0.7.2"},
      {:phoenix, "~> 1.6.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.7"},
      {:ex_prompt, "~> 0.2.0"},
      {:linguist, "~> 0.3.2"},
      {:oban, "~> 2.9"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0.4", override: true},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_dashboard, "~> 0.5.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:pow, "~> 1.0.25"},
      {:sweet_xml, "~> 0.6"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:libcluster, "~> 3.3"},
      {:plug_cowboy, "~> 2.0"},
      {:waffle, "~> 1.1"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "npm.install": [],
    ]
  end
end

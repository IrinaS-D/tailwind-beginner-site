defmodule Legendary.Admin.Kaffy.EditorExtension do
  @moduledoc """
  Bring in additional CSS and JS for the admin interface e.g. the
  markdown editor library.
  """

  import Phoenix.HTML.Tag, only: [tag: 2]

  def stylesheets(_conn) do
    [
      {:safe, ~s(<link rel="stylesheet" href="/css/admin.css" />)},
      {:safe, ~s(<link rel="stylesheet" href="/css/app.css" />)},
      tag(:meta, property: "og:site_name", content: Legendary.I18n.t!("en", "site.title"))
    ]
  end

  def javascripts(_conn) do
    [
      {:safe, ~s(<script src="/js/admin.js"></script>)},
      {:safe, ~s(<script src="/js/app.js"></script>)},
    ]
  end
end

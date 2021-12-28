defmodule AppWeb.ExampleLive do
  use Surface.LiveView

  alias AppWeb.Components.ExampleComponent

  def render(assigns) do
    ~F"""
    <ExampleComponent>
      Hi there!
    </ExampleComponent>
    """
  end
end
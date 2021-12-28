defmodule AppWeb.Components.ExampleComponent do
  use Surface.Component

  slot default, required: true

  def render(assigns) do
    ~F"""
    <h1><#slot/></h1>
    """
  end
end
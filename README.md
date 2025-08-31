# InertiaBuilder

InertiaBuilder lets you declare [Inertia.js](https://inertiajs.com/) props for your Rails frontend components using a [Jbuilder](https://github.com/rails/jbuilder)-like syntax.

It is built on top of the [inertia-rails](https://github.com/inertiajs/inertia-rails) gem.

Here is an example:

```ruby
# app/controllers/messages_controller.rb

class MessagesController < ApplicationController
  # Shared variables will be automatically included in the props.
  inertia_share user: Current.user

  def show
    @message = Message.find(params[:id])
  end
end
```

```ruby
# app/views/messages/show.html.inertia

prop.message do
  prop.content @message.content

  prop.author do
    prop.name @message.author.name
    prop.email @message.author.email
    prop.url url_for(@message.author, format: :json)
  end

  prop.comments @message.comments do |comment|
    prop.partial! comment
  end
end
```

This will provide the following props to your React component:

```jsx
// app/javascript/pages/messages/show.jsx

export default function Message({ user, message }) {
  return (
    <div>
      <p>Hi, {user.name}</p>
      <p>{message.content}</p>
      <a href={message.author.url}>
        {message.author.name} &lt;{message.author.email}&gt;
      </a>
      <div>
        <span>Comments</span>
        {message.comments.map(comment => (
          <Comment key={comment.id} comment={comment} />
        ))}
      </div>
    </div>
  );
}
```

InertiaBuilder extends the Jbuilder DSL. See the [Jbuilder documentation](https://github.com/rails/jbuilder) for more examples.

## Installation

Add the `inertia_builder` gem to your Gemfile:

```ruby
gem 'inertia_builder'
```

If you have an inertia-rails initializer, **make sure to disable `default_render`**:

```ruby
# config/initializers/inertia_rails.rb

InertiaRails.configure do |config|
  config.default_render = false
end
```

You also do not need to call `use_inertia_instance_props`.

## Contributing

Contributions are welcome!

- Fork the repository and create a feature branch.
- Make your changes with clear, focused commits.
- Add tests for new behavior and ensure the test suite passes.
- Run linters/formatters if configured.
- Open a pull request describing the change and motivation.

For significant changes, consider opening an issue first to discuss what you’d like to change.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

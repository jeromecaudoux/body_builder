BodyBuilder is a widget that manage the loading of your data. For each situation the widget will rebuild with a BodyState containing all the necessary information to display the right widget.

## Before you begin

BodyBuilder manage the loading of your data by 3 different ways: state, cache and data:

**state** is a ChangeNotifier that contains data already retrieved. The BodyBuilder will listen to it and rebuild when the state changes.

**cache** is a Future that will be called if the state is empty and returns a nullable value. It will be called before displaying the loading widget.

**data** is a Future that will be called if the state is empty. If an error occurs, the error widget will be displayed.

The paginated data is also supported (See sample app).

## Simple usage

Here is a simple example of how to use the BodyBuilder widget.

If you want to let the BodyBuilder display a loading and error widget:
```dart
BodyBuilder(
    key: _key,
    providers: [
        BodyProvider(
            state: _state,
            cache: _cacheProvider,
            data: _dataProvider,
        )
    ],
    builder: (String data) => Center(child: Text(data)),
);
```

If you want to manage the loading and error widget yourself, you can use the customBuilder and use the BodyState to display the right widget:
```dart
BodyBuilder(
    key: _key,
    providers: [
        BodyProvider(
            state: _state,
            cache: _cacheProvider,
            data: _dataProvider,
        )
    ],
    customBuilder: (BodyState state) => Center(child: Text('data: ${state.data} (isCache: ${state.isCache}), error: ${state.error}, loading: ${state.loading}')),
);
```

You can override the default loading and error widget by using the loadingBuilder and errorBuilder.

You can also configure all BodyBuilder by using **BodyBuilder.setDefaultConfig**.

## How it works

<img src="https://github.com/jeromecaudoux/body_builder/blob/main/files/diagram.jpg" width="600" />

## StateProvider

A few StateProvider are available to help you in different situations.

**SimpleStateProvider** can be used to handle a single value. (Example: You want to retrieve a config from your server)
```dart 
    BodyProvider(
        state: context.read<BasicSampleState>(),
        ...
    )
```

**RelatedStateProvider** is a map of SimpleStateProvider sorted with a key of your choice. (Example: You want to retrieve many users and sort them by their id)
```dart 
    BodyProvider(
        state: context.read<MultiProviderSampleState>().byId(...),
        ...
    )
```

**PaginatedState** allows you to retrieve a paginated list of data. (See sample app for example)

**RelatedPaginatedStates** is a map of PaginatedState sorted with a key of your choice. (Example: You want to sort the paginated followers of your users by their id)
```dart 
    BodyProvider(
        state: context.read<YourRelatedPaginatedStates>().byId(...),
        ...
    )
```

**ChangeNotifierExt.map** allows you to convert any ChangeNotifier to a StateProvider via map function.

```dart 
final StateProvider<...> state = context.read<YouState>().map((YouState state) => state.someValue);
```

## Additional information

If you find a bug or want a feature, please file an issue on github <a href="https://github.com/jeromecaudoux/body_builder/issues">Here</a>.

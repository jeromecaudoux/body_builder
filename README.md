**body_builder** is a light and very useful dart only package for flutter that handle the loading of your data from either your states, persistent cache or remote API/else.

<img src="https://raw.githubusercontent.com/jeromecaudoux/body_builder/main/body_builder/files/sample.gif" width="300" />

## How it works
Define a **BodyProvider** linked to your state and cache/remote functions. _(More details on this below)_
```dart  
final _myProvider = BodyProvider(
  state: ...,
  cache: (String? query) => ...,
  data: (String? query) =>  ...,
)
```
Use it with a **BodyBuilder** in your UI:
```dart  
BodyBuilder(
providers: [_myProvider],
builder: (String data) => Text(data),
);
```

[See full example using providers](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder/example/lib/basic_sample_page.dart)

[See full example using riverpod](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/simple_page.dart)

# BodyProvider

A **BodyProvider** is used by the widget BodyBuilder to know what and how to load your data.
The constructor takes 4 parameters, but only **data** is required:

```dart 
const BodyProvider({
this.state,
this.cache,
required this.data,
super.name,
});
```

- **state** contains data already retrieved. The BodyBuilder will listen to it and rebuild when the state changes.
>  **ChangeNotifier**  and **riverpod**'s states are supported. Find more details about the states below.

- **cache** is a Future called if **state** has no data. It is called before displaying the progress widget. A null value may be returned if no cache is available.
```dart
Future<String?> _cacheProvider(String? query) {
  return Future.delayed(
    const Duration(milliseconds: 500),
            () => 'Value from cache',
  );
}
```

- **data** is a Future is called if **state** has no data. It is called after **cache** and along with a progress indicator. It is your responsibility to update your state in this function (cf: *_state.on*).

```dart
Future<String> _dataProvider(String? query) {
  return Future.delayed(
    const Duration(seconds: 2),
            () => 'Value from your API',
  ).then(_state.on);
}
```
# States
The BodyProvider's state parameter requires a  **StateProvider**.
A set of useful states are provided with this package:

- **SimpleStateProvider\<T\>** can be used when you need to store a single object.

```dart
class BasicSampleState extends SimpleStateProvider<String> {}

final _myState = BasicSampleState();

final _myProvider = BodyProvider(
        state: _myState,
        ...
)
```

- **PaginatedState\<T\>** must be used to store paginated data.
  - _PaginatedState_ will store a List\<T\> for each search query _(See BodyBuilder section below)_
  - In your _data_ function, you have to provide a [**PaginatedBase\<T\>**](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder/lib/src/paginated_response.dart) to **_myState.on** to update the existing list. __myState.on_ will then return the entire list to the BodyBuilder. ([See full example](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder/example/lib/paginated_page.dart))

 ```dart
class MyFollowersState extends PaginatedState<String> {}

final _myState = MyFollowersState();

final _myProvider = BodyProvider(  
  state: _myState,  
  data: _getMyFollowers
)

Future<Iterable<String>> _getMyFollowers(String? query) {
  return Future.delayed(const Duration(seconds: 2), () {
   int previousPage = _myState.get(query).page;
   return PaginatedResponse<String>(  
      items: [
        for (int i = 0; i < _itemsPerPage; i++)
          'Follower n°${previousPage * _itemsPerPage + i}',  
      ],  
      page: previousPage + 1,  
      lastPage: 5,  
    );  
  }).then((response) => _myState.on(response, query: query));
```

- **RelatedStateProvider\<K, T\>** is a map of _SimpleStateProvider\<T\>_ sorted by **K**.

 ```dart
class UserByIdRelatedStates extends RelatedStateProvider<String, User> {}

final myRelatedState = UserByIdRelatedStates();

final _myProvider = BodyProvider(  
  state: myRelatedState.byId('123'),  
  ...
)
```

- **RelatedPaginatedStates\<K, T\>** is a map of _PaginatedState\<T\>_ sorted by **K**.
# BodyBuilder

You can trigger a reload of your BodyBuilder by using a GlobalKey like this:

```dart
final GlobalKey<BodyBuilderState> _key = GlobalKey();

@override  
Widget build(BuildContext context) {  
  return Scaffold(  
    appBar: AppBar(  
      title: const Text('Basic'),  
      actions: [  
        IconButton(  
          // Set allowState depending on your needs
          onPressed: () => _key.currentState?.retry(allowState: false),
          icon: const Icon(Icons.refresh),  
        ),  
      ],  
    ),  
    body: BodyBuilder(  
      key: _key,  
      providers: [_myProvider],  
      builder: (_) => Text('My UI'),  
    ),  
  );  
}
```

If you are working with pagination, add a **LoadMore** widget at the end of your list to trigger the next page and display the corresponding progress or error. [See full example](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder/example/lib/paginated_page.dart)
```dart
Widget _buildListView(Iterable<String> items) {  
  return ListView.builder(  
    itemCount: items.length + 1,  
    itemBuilder: (context, index) {  
      if (index == items.length) {  
        return LoadMore(_key);  
      }  
      return ListTile(title: Text(items.elementAt(index)));  
    },  
  );  
}
```

The widget BodyBuilder accept a few parameters:

| Parameter's name  | Type                      | Details                                                                                                                                                                                                                                                                                                                            |
|-------------------|---------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `providers*`      | `Iterable<BodyProvider<T>>?` | List of providers to be used to load your data.                                                                                                                                                                                                                                                                                    |
| `builder*`        | `Function`                | The function to be called with your data or with a BodyState (See details).                                                                                                                                                                                                                                                        |
| `customBuilder*`  | `CustomBuilder`           | A custom builder that you can use to override the progress and or error widgets. It is a function that takes a single parameter **BodyState**.                                                                                                                                                                                     |
| `scrollController`| `ScrollController?`       | You can provide your ScrollController to enable the pull to refresh feature.                                                                                                                                                                                                                                                       |
| `onBeforeRefresh` | `VoidCallback?`           | A simple callback called before forcing the reload when a pull to refresh is triggered. By default, the provided states are cleared from their data (cf method #clear in StateProvider).                                                                                                                                           |
| `clearDataOnRefresh` | `bool`          | If true, the data are cleared and a progress widget is displayed before reloading. Otherwise, only a small progress is displayed at the top.                                                                                                                                                                                       |
| `searchController` | `TextEditingController?`  | You can provide a TextEditingController to support queries. The BodyBuilder will listen to it and force reload when anything changes.                                                                                                                                                                                              |
| `searchFetchDelay` | `Duration`                | While listening to your TextEditingController, a delay is applied to avoid too many reloads while the user is typing.                                                                                                                                                                                                              |
| `animationDuration` | `Duration`                | The transition duration between the progress, error, and your data widgets.                                                                                                                                                                                                                                                        |
| `listenState`     | `bool`                    | Set to true by default. If set to true, then the BodyBuilder will listen to your state(s) and re-call builder/customBuilder when changed.                                                                                                                                                                                          |
| `errorBuilder`    | `ErrorBuilder?`           | Can be used to customize the error widget.                                                                                                                                                                                                                                                                                         |
| `progressBuilder` | `Widget?`                 | Can be used to customize the progress widget.                                                                                                                                                                                                                                                                                      |
| `childWrapper`    | `ChildWrapper`            | Can be used to override the very child of the BodyBuilder.                                                                                                                                                                                                                                                                         |
| `mergeDataStrategy` | `MergeDataStrategy`      | Used when more than one provider is given. If set to **MergeDataStrategy.allAtOne**, the BodyState's data provided to the customBuilder will be null until all providers' data are retrieved. If **MergeDataStrategy.oneByOne** is set, then the BodyState's data will contain each provider's data as soon as they are retrieved. |

## builder, customBuilder and BodyState

If you have a fixed number of BodyProvider, you can get them in your **builder**'s method like this (up to 9 parameters):
```dart  
BodyBuilder(
providers: [_myProvider1, _myProvider2, _myProvider3, ...],
builder: (String data1, int data2, User user3, ...) => Text('Your UI here'),
);
```

If you are using **customBuilder**, you can have as many providers as you want and get the data using the **byType** or **byName**:
```dart 
final _myProvider2 = BodyProvider(
        name: 'my-provider2',
        ...
);

BodyBuilder(
providers: [_myProvider1, _myProvider2, ...],
customBuilder: (BodyState bState) {
BodyState<String>? bState1 = bState.byType<String>();
BodyState<int>? bState2 = bState.byName<int>('my-provider2')

return Text('data1=${bState1?.data} and data2=${bState2?.data}');
}
);
```

**BodyState\<T\>** is a class containing informations about the situation of the associated BodyProvider:
```dart 
final class BodyState<T> {
  final bool isCache;
  final T? data;
  final bool isLoading;
  final Object? error;
  final StackTrace? errorStack;
  ...
}
```

# More details

<img src="https://raw.githubusercontent.com/jeromecaudoux/body_builder/main/body_builder/files/diagram.jpg" width="600" />

## Additional information

If you find a bug or want a feature, please file an issue on github <a href="https://github.com/jeromecaudoux/body_builder/issues">Here</a>.

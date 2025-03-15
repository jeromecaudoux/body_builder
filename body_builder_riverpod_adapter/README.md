
**body_builder_riverpod_adapter** is an extension of the **body_builder** package that provides a way to use **riverpod**'s states with the **BodyProvider**.

# body_builder's states

- **SimpleStateProvider\<T\>** can be used when you need to store a single object.

With riverpod, use **createSimpleStateProvider\<T\>** to create an equivalent StateNotifierProvider . And  **ref.asSimple(_)** to convert it to a valid BodyBuilder's StateProvider.
```dart  
final mySimpleProvider = createSimpleStateProvider<String>();  
  
final myBProvider = Provider<BodyProvider<String>>(  
  (Ref ref) {  
    return BodyProvider(  
      state: ref.asSimple(mySimpleProvider),  
      data: (_) => ref.read(dummyRepProvider).fetchSimple(),  
    );  
  },  
);
```  
[See full example](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/simple_page.dart)

- **RelatedStateProvider\<K, T\>** is a map of _SimpleStateProvider\<T\>_ sorted by **K**.

With riverpod, use **createFamilySimpleStateProvider\<K, T\>()** to create an equivalent StateNotifierProvider. And  **ref.asFamilySimple(_)** to convert it to a valid BodyBuilder's StateProvider.
 ```dart  
final myRelatedSimpleProvider = createFamilySimpleStateProvider<int, String>();  
  
final myRelatedSimpleBProvider = Provider.family<BodyProvider<String>, int>(  
  (Ref ref, int id) {  
    return BodyProvider(  
      state: ref.asFamilySimple(myRelatedSimpleProvider, id),  
      data: (query) => ref.read(dummyRepProvider).fetchRelatedSimple(id),  
    );  
  },  
);
```  
[See full example](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/related_simple_page.dart)

- **PaginatedState\<T\>** must be used to store paginated data.

With riverpod, use **createPaginatedStateProvider\<T\>()** to create an equivalent StateNotifierProvider. And  **ref.asPaginated(_)** to convert it to a valid BodyBuilder's StateProvider.
 ```dart  
final myPaginatedProvider = createPaginatedStateProvider<String>();  
  
final myPaginatedBProvider = Provider<BodyProvider<Iterable<String>>>(  
  (Ref ref) {  
    return BodyProvider(  
      state: ref.asPaginated(myPaginatedProvider),  
      data: (query) => ref.read(dummyRepProvider).fetchPaginated(query),  
    );  
  },  
);
```  
[See full example](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/paginated_page.dart)


- **RelatedPaginatedStates\<K, T\>** is a map of _PaginatedState\<T\>_ sorted by **K**.

With riverpod, use **createFamilyPaginatedStateProvider\<K, T\>()** to create an equivalent StateNotifierProvider. And  **ref.asFamilyPaginated(_)** to convert it to a valid BodyBuilder's StateProvider.
```dart
final myRelatedPaginatedProvider =  
    createFamilyPaginatedStateProvider<int, String>();  
  
final myRelatedPaginatedBProvider =  
    Provider.family<BodyProvider<Iterable<String>>, int>(  
  (Ref ref, int id) {  
    return BodyProvider(  
      state: ref.asFamilyPaginated(myRelatedPaginatedProvider, id),  
      data: (query) => ref.read(dummyRepProvider).fetchById(id, query),  
    );  
  },  
);
```
[See full example](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/related_paginated_page.dart)

# BodyBuilder
Here is the full example of a BodyBuilder with a BodyProvider using a **createFamilyPaginatedStateProvider\<K, T\>()**.
```dart
import 'package:body_builder/body_builder.dart';  
import 'package:body_builder_example/core/dummy_repository.dart';  
import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  

class RelatedPaginatedPage extends ConsumerStatefulWidget {  
  const RelatedPaginatedPage({super.key});  
  
  @override  
  ConsumerState<RelatedPaginatedPage> createState() => _PaginatedPageState();  
}  
  
class _PaginatedPageState extends ConsumerState<RelatedPaginatedPage> {  
  final GlobalKey<BodyBuilderState> _key = GlobalKey();  
  int _userId = 1;  
  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      appBar: AppBar(  
        title: const Text('Related paginated'),  
        actions: [  
          IconButton(  
            onPressed: () {  
              ref.read(myRelatedPaginatedProvider).clear();  
              _key.currentState?.retry();  
            },  
            icon: const Icon(Icons.refresh),  
          ),  
          IconButton(  
            onPressed: () {  
              setState(() {  
                _userId--;  
              });  
              _key.currentState?.retry(allowState: true);  
            },  
            icon: const Icon(Icons.remove),  
          ),  
          IconButton(  
            onPressed: () {  
              setState(() {  
                _userId++;  
              });  
              _key.currentState?.retry(allowState: true);  
            },  
            icon: const Icon(Icons.add),  
          ),  
        ],  
      ),  
      body: Column(  
        children: [  
          Text('Current user id: $_userId'),  
          Expanded(  
            child: BodyBuilder(  
              key: _key,  
              providers: [ref.read(myRelatedPaginatedBProvider(_userId))],  
              builder: _buildListView,  
            ),  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildListView(Iterable<String> items) {  
    return ListView.builder(  
      itemCount: items.length + 1,  
      itemBuilder: (context, index) {  
        if (index == items.length) {
          /// - This widget will trigger [BodyBuilderState.loadMoreIfNeeded]
          /// when it is displayed on screen.
          /// - It has a simple error handling mechanism with a retry button and
          /// circular progress indicator.
          return LoadMore(_key);  
        }  
        return ListTile(title: Text(items.elementAt(index)));  
      },  
    );  
  }  
}
```

## Additional information

If you find a bug or want a feature, please file an issue on github <a href="https://github.com/jeromecaudoux/body_builder/issues">Here</a>.


**body_builder_riverpod_adapter** is an extension of the **body_builder** package that provides a way to use **riverpod**'s states with the **BodyProvider**.

# body_builder's states

- **SimpleStateProvider\<T\>** can be used when you need to store a single object.

With riverpod, use **createSimpleStateProvider\<T\>** to create an equivalent StateNotifierProvider . And  **ref.asSimple(_)** to convert it to a valid BodyBuilder's StateProvider.
```dart  
final mySimpleProvider = createSimpleStateProvider<String>();  
  
final myBodyProvider = Provider<BodyProvider<String>>(  
  (Ref ref) {  
    return BodyProvider(  
      state: ref.asSimple(mySimpleProvider),  
      data: (_) => ref.read(dummyRepProvider).fetchSimple(),  
    );  
  },  
);
```  

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

# BodyBuilder


## Additional information

If you find a bug or want a feature, please file an issue on github <a href="https://github.com/jeromecaudoux/body_builder/issues">Here</a>.

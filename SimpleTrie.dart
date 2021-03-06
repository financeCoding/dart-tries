#library ("trie");
#import ("Trie.dart");

class SimpleTrie<T> implements Trie<T>{
  _SimpleTrieNode<T> _root;
  int _numberOfEntries;
  int _numberOfNodes;
  List<num> _childHistogram;

  SimpleTrie(){
    _numberOfEntries = 0;
    _numberOfNodes = 0;
    _childHistogram = new List<num>(100);
    for (int i=0; i<_childHistogram.length; i++) {
      _childHistogram[i] = 0;
    }
  }

  void operator []=(String key, T item) => _add(key, item);

  T operator [](String key) => _get(key);

  num size() => _numberOfEntries;

  bool isEmpty() => _root === null;

  void clear() {
    _root = null;
    _numberOfEntries = 0;
  }

  void _add(String  key, T value) {
    if (isEmpty()) {
      _root = new _SimpleTrieNode<T>(-1);
    }
    _SimpleTrieNode<T> node = _root;
    _SimpleTrieNode<T> previousNode = null;
    int i = 0;
    while (i < key.length) {
      previousNode = node;
      node = node.getChildNode(key.charCodeAt(i));
      if (node == null) break;
      i++;
    }
    if (i < key.length) {
      // Start from the parent.
      node = previousNode;
      // Add one node for each char.
      while (i < key.length) {
        node = node.addNode(key.charCodeAt(i++));
      }
    }
    if (!node.hasValue()) {
      node.setKeyValue(key, value);
      _numberOfEntries++;
    }
  }

  T _get(String str) {
    _SimpleTrieNode<T> node = _walkToNode(str);
    return node !== null ? node.value : null;
  }

  _SimpleTrieNode<T> _walkToNode(String pre) {
    if (pre === null) {
      return _root;
    }
    _SimpleTrieNode<T> node = _root;
    int i = 0;
    while(i < pre.length && node!= null) {
      node = node.getChildNode(pre.charCodeAt(i));
      i++;
    }
    return node;
  }

  void forEach(void f(String key, T value)) {
    _walkAndApply(_root, f);
  }

  void _walkAndApply(_SimpleTrieNode<T> node, void f(String key, T value)) {
    if (node != null) {
      if(node.hasValue()) {
        f(node.key, node.value);
      }
      Collection<_SimpleTrieNode<T>> children = node.getAllChildren();
      if (children != null) {
        for (_SimpleTrieNode<T> child in children) {
          _walkAndApply(child, f);
        }
      }
    }
  }

  Collection<T> getValuesWithPrefix(String pre) {
    List<T> values = new List<T>();
    _SimpleTrieNode node = _walkToNode(pre);
    _walkAndApply(node, void _(String key, T value) {
      values.add(value);
    });
    return values;
  }

  Collection<String> getKeysWithPrefix(String pre) {
    List<String> keys = new List<String>();
    _SimpleTrieNode node = _walkToNode(pre);
    _walkAndApply(node, void _(String key, T value) {
      keys.add(key);
    });
    return keys;
  }

  Map<String, T> getKeyValuesWithPrefix(String pre) {
    LinkedHashMap<String, T> res = new LinkedHashMap<String, T>();
    _SimpleTrieNode node = _walkToNode(pre);
    _walkAndApply(node, void _(String key, T value) {
      res[key] = value;
    });
    return res;
  }

  void calculateMetrics() {
    _calculateStats(_root);
  }

  void _calculateStats(_SimpleTrieNode<T> node ) {
    if (node != null) {
      _numberOfNodes++;
      Collection<_SimpleTrieNode<T>> children = node.getAllChildren();
      if (children != null) {
        _childHistogram[children.length]++;
        for (_SimpleTrieNode<T> child in children) {
          _calculateStats(child);
        }
      } else {
        _childHistogram[0]++;
      }
    }
  }

  void dump() {
    print ("Number of entries: $_numberOfEntries");
    print ("Number of nodes: $_numberOfNodes");
    for (int i=0; i<_childHistogram.length; i++) {
      if (_childHistogram[i] != 0) {
        print ("Nodes with $i children: ${_childHistogram[i]}");
      }
    }
  }
}

class _SimpleTrieNode<T> {
  String _key;
  T _value;
  int _c;
  List<_SimpleTrieNode<T>> _children = null;

  bool hasValue() => _value !== null;

  T get value() => _value;

  String get key() => _key;

  _SimpleTrieNode(this._c);

  _SimpleTrieNode<T> getChildNode(int c) {
    if (_children === null) {
      return null;
    }
    int pos = _getChildIndex(c);
    return pos >= 0 ? _children[pos] : null;
  }

  Collection<_SimpleTrieNode<T>> getAllChildren() => _children;

  // Search based on index values of children array.
  // Returns index of node if it already exists,
  // -(pos +1) position to insert, if no element exist with given index
  int _getChildIndex(int c) {
      if (_children === null) {
          return -1;
      }
      num size = _children.length;
      // Fast case for single children nodes.
      if (size == 1) {
        return _children[0]._c == c ? 0 :
          _children[0]._c < c ? -2 : -1;
      }
      // Apply binary search otherwise.
      int low = 0;
      int high = size - 1;
      while (low <= high) {
          int mid = (low + high) >> 1;
          _SimpleTrieNode<T> midNode = _children[mid];
          if (midNode._c > c) {
            high = mid - 1;
          } else if (midNode._c < c) {
            low = mid + 1;
          } else {
              return mid;
          }
      }
      return -(low + 1);
  }

  // Add node for given char
  _SimpleTrieNode<T> addNode(int c) {
    if (_children == null) {
      _children = new List<_SimpleTrieNode<T>>();
    }
    int pos = _getChildIndex(c);
    if (pos < 0) {
      _SimpleTrieNode<T> emptyNode = new _SimpleTrieNode<T>(c);
      _children.insertRange(-(pos + 1), 1, emptyNode);
      return emptyNode;
    }
    return _children[pos];
  }

  void setKeyValue(String key, T value){
    this._key = key;
    this._value = value;
  }

  String toString() {
    return "char: $_c key: $_key value:$_value";
  }

}
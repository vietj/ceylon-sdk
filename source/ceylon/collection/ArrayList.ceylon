"A [[MutableList]] implemented using a backing [[Array]].
 Also:

 - a [[Stack]], where the top of the stack is the _last_
   element of the list, and
 - a [[Queue]], where the front of the queue is the first
   element of the list and the back of the queue is the
   last element of the list.

 The size of the backing `Array` is called the _capacity_
 of the `ArrayList`. The capacity of a new instance is
 specified by the given [[initialCapacity]]. The capacity is
 increased when [[size]] exceeds the capacity. The new
 capacity is the product of the current capacity and the
 given [[growthFactor]]."
by ("Gavin King")
shared class ArrayList<Element>
        (initialCapacity = 0, growthFactor=1.5,
                elements = {})
        satisfies MutableList<Element> &
                  Stack<Element> & Queue<Element> {

    "The initial size of the backing array."
    Integer initialCapacity;

    "The factor used to determine the new size of the
     backing array when a new backing array is allocated."
    Float growthFactor;

    "The initial elements of the list."
    {Element*} elements;

    "initial capacity cannot be negative"
    assert (initialCapacity >= 0);

    "initial capacity too large"
    assert (initialCapacity <= runtime.maxArraySize);

    "growth factor must be at least 1.0"
    assert (growthFactor >= 1.0);

    Array<Element?> store(Integer capacity)
            => arrayOfSize<Element?>(capacity, null);

    variable Array<Element?> array 
            = Array<Element?>(elements);

    variable Integer length = array.size;

    size => length;

    if (length < initialCapacity) {
        value newArray = store(initialCapacity);
        array.copyTo(newArray, 0, 0, length);
        array = newArray;
    }

    void grow(Integer increment) {
        value neededCapacity = length + increment;
        value maxArraySize = runtime.maxArraySize;
        if (neededCapacity > maxArraySize) {
            throw OverflowException(); //TODO: give it a message!
        }
        if (neededCapacity > array.size) {
            value grownCapacity 
                    = (neededCapacity * growthFactor).integer;
            value newCapacity 
                    = grownCapacity < neededCapacity || 
                      grownCapacity > maxArraySize
                        then maxArraySize 
                        else grownCapacity;
            value grown = store(newCapacity);
            array.copyTo(grown);
            array = grown;
        }
    }

    shared actual 
    void add(Element element) {
        grow(1);
        array.set(length++, element);
    }

    shared actual 
    void addAll({Element*} elements) {
        value sequence = elements.sequence();
        grow(sequence.size);
        for (element in sequence) {
            array.set(length++, element);
        }
    }

    shared actual
    void clear() {
        length = 0;
        array = store(initialCapacity);
    }

    "The size of the backing array, which must be at least
     as large as the [[size]] of the list."
    shared Integer capacity => array.size;
    assign capacity {
        "capacity must be at least as large as list size"
        assert (capacity >= size);
        "capacity too large"
        assert (capacity <= runtime.maxArraySize);
        value resized = store(capacity);
        array.copyTo(resized, 0, 0, length);
        array = resized;
    }

    getFromFirst(Integer index) 
            => if (0 <= index < length)
            then array.getFromFirst(index)
            else null;
    
    shared actual 
    Boolean contains(Object element) {
        for (index in 0:size) {
            if (exists elem 
                    = array.getFromFirst(index)) {
                if (elem==element) {
                    return true;
                }
            }
        }
        else {
            return false;
        }
    }
    
    iterator() => object satisfies Iterator<Element> {
        variable value index = 0;
        shared actual Finished|Element next() {
            if (index<length) {
                if (exists next 
                        = array.getFromFirst(index++)) {
                    return next;
                }
                else {
                    assert (is Element null);
                    return null;
                }
            }
            else {
                return finished;
            }
        }
    };
    
    shared actual 
    void insert(Integer index, Element element) {
        "index may not be negative or greater than the
         length of the list"
        assert (0 <= index <= length);
        grow(1);
        if (index < length) {
            array.copyTo(array, 
                index, index+1, length-index);
        }
        length++;
        array.set(index, element);
    }
    
    shared actual 
    void insertAll(Integer index, {Element*} elements) {
        "index may not be negative or greater than the
         length of the list"
        assert (0 <= index <= length);
        value sequence = elements.sequence();
        value size = sequence.size;
        if (size>0) {
            grow(size);
            if (index < length) {
                array.copyTo(array, 
                    index, index+size, length-index);
            }
            variable value i = index;
            for (element in sequence) {
                array.set(i++, element);
            }
            length+=size;
        }
    }

    shared actual 
    Element? delete(Integer index) {
        if (0 <= index < length) {
            Element? result = array[index];
            array.copyTo(array, 
                index+1, index, length-index-1);
            length--;
            array.set(length, null);
            return result;
        }
        else {
            return null;
        }
    }

    shared actual 
    Integer remove(Element&Object element) {
        variable value i=0;
        variable value j=0;
        while (i<length) {
            if (exists elem = array[i++]) {
                if (elem!=element) {
                    array.set(j++,elem);
                }
            }
            else {
                array.set(j++, null);
            }
        }
        length=j;
        while (j<i) {
            array.set(j++, null);
        }
        return i-length;
    }

    shared actual 
    Integer removeAll({<Element&Object>*} elements) {
        Category<> set = HashSet { *elements };
        variable value i=0;
        variable value j=0;
        while (i<length) {
            if (exists elem = array[i++]) {
                if (!elem in set) {
                    array.set(j++,elem);
                }
            }
            else {
                array.set(j++, null);
            }
        }
        length=j;
        while (j<i) {
            array.set(j++, null);
        }
        return i-length;
    }

    shared actual 
    Boolean removeFirst(Element&Object element) {
        if (exists index 
                = firstOccurrence(element)) {
            delete(index);
            return true;
        }
        else {
            return false;
        }
    }

    shared actual 
    Boolean removeLast(Element&Object element) {
        if (exists index 
                = lastOccurrence(element)) {
            delete(index);
            return true;
        }
        else {
            return false;
        }
    }

    shared actual 
    void prune() {
        variable value i=0;
        variable value j=0;
        while (i<length) {
            if (exists element = array[i++]) {
                array.set(j++,element);
            }
        }
        length=j;
        while (j<i) {
            array.set(j++, null);
        }
    }

    shared actual 
    void replace
            (Element&Object element, Element replacement) {
        variable value i=0;
        while (i<length) {
            if (exists elem = array[i], 
                elem==element) {
                array.set(i, replacement);
            }
            i++;
        }
    }

    shared actual 
    Boolean replaceFirst
            (Element&Object element, Element replacement) {
        if (exists index 
                = firstOccurrence(element)) {
            set(index, replacement);
            return true;
        }
        else {
            return false;
        }
    }

    shared actual 
    Boolean replaceLast
            (Element&Object element, Element replacement) {
        if (exists index 
                = lastOccurrence(element)) {
            set(index, replacement);
            return true;
        }
        else {
            return false;
        }
    }

    shared actual 
    void infill(Element replacement) {
        variable value i = 0;
        while (i < length) {
            if (!array[i] exists) {
                array.set(i, replacement);
            }
            i++;
        }
    }

    shared actual 
    void set(Integer index, Element element) {
        "index may not be negative or greater than the
         last index in the list"
        assert (0<=index<length);
        array.set(index,element);
    }

    shared actual 
    List<Element> span(Integer from, Integer to) {
        value [start, len, reversed]
                = spanToMeasure(from, to, length);
        value result = ArrayList {
            initialCapacity = len; 
            growthFactor = growthFactor; 
            elements = skip(start).take(len); 
        };
        return reversed then result.reversed else result;
    }

    shared actual 
    void deleteSpan(Integer from, Integer to) {
        value [start, len, _]
                = spanToMeasure(from, to, length);
        if (start < length && len > 0) {
            value fstTrailing = start + len;
            array.copyTo(array, 
                fstTrailing, start, length - fstTrailing);
            variable value i = length-len;
            while (i < length) {
                array.set(i++, null);
            }
            length -= len;
        }
    }

    measure(Integer from, Integer length) 
            => span(*measureToSpan(from, length));
    
    deleteMeasure(Integer from, Integer length) 
            => deleteSpan(*measureToSpan(from, length));
    
    shared actual 
    void truncate(Integer size) {
        assert (size >= 0);
        if (size < length) {
            variable value i = size;
            while (i < length) {
                array.set(i++, null);
            }
            length = size;
        }
    }

    spanFrom(Integer from) 
            => from >= length
                then ArrayList()
                else span(from, length-1);

    spanTo(Integer to) 
            => to < 0 then ArrayList() else span(0, to);

    first => if (length > 0) then array[0] else null;
    
    lastIndex => length >= 1 then length - 1;

    equals(Object that) 
            => (super of List<Element>).equals(that);

    hash => (super of List<Element>).hash;

    push(Element element) => add(element);

    pop() => deleteLast();

    top => last;

    offer(Element element) => add(element);

    accept() => deleteFirst();

    back => last;

    front => first;
    
    shared actual 
    ArrayList<Element> clone() 
            => ArrayList(size, growthFactor, this);
    
    "Sorts the elements in this list according to the 
     order induced by the given 
     [[comparison function|comparing]]. Null elements are 
     sorted to the end of the list. This operation modifies 
     the list."
    shared void sortInPlace(
        "A comparison function that compares pairs of
         non-null elements of the array."
        Comparison comparing(Element&Object x, Element&Object y)) {
        array.sortInPlace((x, y) { 
            if (exists x, exists y) {
                return comparing(x, y);
            }
            else {
                if (x exists && !y exists) {
                    return smaller;
                }
                else if (y exists && !x exists) {
                    return larger;
                }
                else {
                    return equal;
                }
            }
        });
    }
    
    shared actual
    void each(void step(Element element)) {
        if (is Element null) {
            array.take(length)
                 .each((e) { 
                step(e else null); 
            });
        }
        else {
            array.take(length)
                 .each((e) { 
                assert (exists e);
                step(e);
            });
        }
    }
    
    shared actual
    Integer count(Boolean selecting(Element element)) {
        if (is Element null) {
            return array.take(length)
                    .count((e) => selecting(e else null));
        }
        else {
            return array.take(length)
                    .count((e) { 
                assert (exists e);
                return selecting(e);
            });
        }
    }
    
    shared actual
    Boolean every(Boolean selecting(Element element)) {
        if (is Element null) {
            return array.take(length)
                    .every((e) => selecting(e else null));
        }
        else {
            return array.take(length)
                    .every((e) { 
                assert (exists e);
                return selecting(e);
            });
        }
    }
    
    shared actual
    Boolean any(Boolean selecting(Element element)) {
        if (is Element null) {
            return array.take(length)
                    .any((e) => selecting(e else null));
        }
        else {
            return array.take(length)
                    .any((e) { 
                assert (exists e);
                return selecting(e);
            });
        }
    }
    
    shared actual
    Element? find(Boolean selecting(Element&Object element)) 
            => array.find(selecting);
    
    shared actual
    Element? findLast(Boolean selecting(Element&Object element)) 
            => array.findLast(selecting);
    
    shared actual 
    Result|Element|Null reduce<Result>(
        Result accumulating(Result|Element partial, 
                            Element element)) {
        if (is Element null) {
            return array.take(length)
                    .reduce<Result>((partial, element) 
                    => accumulating(partial else null, 
                                    element else null));
        }
        else {
            return array.take(length)
                    .reduce<Result>((partial, element) {
                assert (exists partial, exists element);
                return accumulating(partial, element);
            });
        }
    }
    
    //TODO: are the following really beneficial?
    
    firstOccurrence(Anything element) 
            => if (exists result 
                        = array.firstOccurrence(element), 
                   result<length) 
            then result 
            else null;
    
    lastOccurrence(Anything element) 
            => if (exists result 
                        = array.lastOccurrence(element), 
                   result<length) 
            then result 
            else null;
    
    "Efficiently copy the elements in the segment
     `sourcePosition:length` of this list to the segment 
     `destinationPosition:length` of the given 
     [[destination]] `ArrayList` or `Array`."
    shared void copyTo(
        "The list into which to copy the elements."
        ArrayList<Element>|Array<Element?> destination,
        "The index of the first element in this array to 
         copy."
        Integer sourcePosition = 0,
        "The index in the given array into which to copy the 
         first element."
        Integer destinationPosition = 0,
        "The number of elements to copy."
        Integer length 
                = smallest(size - sourcePosition,
                    destination.size - destinationPosition)) {
        
        "length may not be negative"
        assert (length>=0);
        "illegal starting position in source list"
        assert (0<=sourcePosition<size-length);
        "illegal starting position in destination list"
        assert (0<=destinationPosition<destination.size-length);
        
        array.copyTo { 
            length = length; 
            sourcePosition = sourcePosition; 
            destinationPosition = destinationPosition; 
            destination = 
                    switch (destination)
                    case (is Array<Element?>)
                        destination
                    case (is ArrayList<Element>)
                        destination.array;
        }; 
    }
    
}

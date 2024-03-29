/*
 * Copyright (c) 2004-2007 Apple Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
/*
  Implementation of the weak / associative references for non-GC mode.
*/


#include "objc-private.h"
#include <objc/message.h>
#include <map>

#if _LIBCPP_VERSION
#   include <unordered_map>
#else
#   include <tr1/unordered_map>
    using namespace tr1;
#endif


// wrap all the murky C++ details in a namespace to get them out of the way.

namespace objc_references_support {
    struct DisguisedPointerEqual {
        bool operator()(uintptr_t p1, uintptr_t p2) const {
            return p1 == p2;
        }
    };
    
    struct DisguisedPointerHash {
        uintptr_t operator()(uintptr_t k) const {
            // borrowed from CFSet.c
#if __LP64__
            uintptr_t a = 0x4368726973746F70ULL;
            uintptr_t b = 0x686572204B616E65ULL;
#else
            uintptr_t a = 0x4B616E65UL;
            uintptr_t b = 0x4B616E65UL; 
#endif
            uintptr_t c = 1;
            a += k;
#if __LP64__
            a -= b; a -= c; a ^= (c >> 43);
            b -= c; b -= a; b ^= (a << 9);
            c -= a; c -= b; c ^= (b >> 8);
            a -= b; a -= c; a ^= (c >> 38);
            b -= c; b -= a; b ^= (a << 23);
            c -= a; c -= b; c ^= (b >> 5);
            a -= b; a -= c; a ^= (c >> 35);
            b -= c; b -= a; b ^= (a << 49);
            c -= a; c -= b; c ^= (b >> 11);
            a -= b; a -= c; a ^= (c >> 12);
            b -= c; b -= a; b ^= (a << 18);
            c -= a; c -= b; c ^= (b >> 22);
#else
            a -= b; a -= c; a ^= (c >> 13);
            b -= c; b -= a; b ^= (a << 8);
            c -= a; c -= b; c ^= (b >> 13);
            a -= b; a -= c; a ^= (c >> 12);
            b -= c; b -= a; b ^= (a << 16);
            c -= a; c -= b; c ^= (b >> 5);
            a -= b; a -= c; a ^= (c >> 3);
            b -= c; b -= a; b ^= (a << 10);
            c -= a; c -= b; c ^= (b >> 15);
#endif
            return c;
        }
    };
    
    struct ObjectPointerLess {
        bool operator()(const void *p1, const void *p2) const {
            return p1 < p2;
        }
    };
    
    struct ObjcPointerHash {
        uintptr_t operator()(void *p) const {
            return DisguisedPointerHash()(uintptr_t(p));
        }
    };

    // STL allocator that uses the runtime's internal allocator.
    
    template <typename T> struct ObjcAllocator {
        typedef T                 value_type;
        typedef value_type*       pointer;
        typedef const value_type *const_pointer;
        typedef value_type&       reference;
        typedef const value_type& const_reference;
        typedef size_t            size_type;
        typedef ptrdiff_t         difference_type;

        template <typename U> struct rebind { typedef ObjcAllocator<U> other; };

        template <typename U> ObjcAllocator(const ObjcAllocator<U>&) {}
        ObjcAllocator() {}
        ObjcAllocator(const ObjcAllocator&) {}
        ~ObjcAllocator() {}

        pointer address(reference x) const { return &x; }
        const_pointer address(const_reference x) const { 
            return x;
        }

        pointer allocate(size_type n, const_pointer = 0) {
            return static_cast<pointer>(::malloc(n * sizeof(T)));
        }

        void deallocate(pointer p, size_type) { ::free(p); }

        size_type max_size() const { 
            return static_cast<size_type>(-1) / sizeof(T);
        }

        void construct(pointer p, const value_type& x) { 
            new(p) value_type(x); 
        }

        void destroy(pointer p) { p->~value_type(); }

        void operator=(const ObjcAllocator&);

    };

    template<> struct ObjcAllocator<void> {
        typedef void        value_type;
        typedef void*       pointer;
        typedef const void *const_pointer;
        template <typename U> struct rebind { typedef ObjcAllocator<U> other; };
    };
  
    typedef uintptr_t disguised_ptr_t;
    inline disguised_ptr_t DISGUISE(id value) { return ~uintptr_t(value); }
    inline id UNDISGUISE(disguised_ptr_t dptr) { return id(~dptr); }
  
    // ObjcAssociation就是关联对象类
    class ObjcAssociation {
        uintptr_t _policy;
        // 值
        id _value;
    public:
        // 构造函数
        ObjcAssociation(uintptr_t policy, id value) : _policy(policy), _value(value) {}
        // 默认构造函数，参数分别为0和nil
        ObjcAssociation() : _policy(0), _value(nil) {}

        uintptr_t policy() const { return _policy; }
        id value() const { return _value; }
        
        bool hasValue() { return _value != nil; }
    };

#if TARGET_OS_WIN32
    typedef hash_map<void *, ObjcAssociation> ObjectAssociationMap;
    typedef hash_map<disguised_ptr_t, ObjectAssociationMap *> AssociationsHashMap;
#else
    typedef ObjcAllocator<std::pair<void * const, ObjcAssociation> > ObjectAssociationMapAllocator;
    
    // ObjectAssociationMap是字典，key是从外面传过来的key，例如@selector(hello),value是关联对象，也就是
    // ObjectAssociation
    class ObjectAssociationMap : public std::map<void *, ObjcAssociation, ObjectPointerLess, ObjectAssociationMapAllocator> {
    public:
        void *operator new(size_t n) { return ::malloc(n); }
        void operator delete(void *ptr) { ::free(ptr); }
    };
    typedef ObjcAllocator<std::pair<const disguised_ptr_t, ObjectAssociationMap*> > AssociationsHashMapAllocator;
    
    // AssociationsHashMap是字典，key是对象的disguised_ptr_t值，value是ObjectAssociationMap
    class AssociationsHashMap : public unordered_map<disguised_ptr_t, ObjectAssociationMap *, DisguisedPointerHash, DisguisedPointerEqual, AssociationsHashMapAllocator> {
    public:
        void *operator new(size_t n) { return ::malloc(n); }
        void operator delete(void *ptr) { ::free(ptr); }
    };
#endif
}

using namespace objc_references_support;

// class AssociationsManager manages a lock / hash table singleton pair.
// Allocating an instance acquires the lock, and calling its assocations()
// method lazily allocates the hash table.

spinlock_t AssociationsManagerLock;

class AssociationsManager {
    // associative references: object pointer -> PtrPtrHashMap.
    // AssociationsManager中只有一个变量AssociationsHashMap
    static AssociationsHashMap *_map;
public:
    // 构造函数中加锁
    AssociationsManager()   { AssociationsManagerLock.lock(); }
    // 析构函数中释放锁
    ~AssociationsManager()  { AssociationsManagerLock.unlock(); }
    // 构造函数、析构函数中加锁、释放锁的操作，保证了AssociationsManager是线程安全的
    
    AssociationsHashMap &associations() {
        // AssociationsHashMap 的实现可以理解成单例对象
        if (_map == NULL)
            _map = new AssociationsHashMap();
        return *_map;
    }
};

AssociationsHashMap *AssociationsManager::_map = NULL;

// expanded policy bits.

enum { 
    OBJC_ASSOCIATION_SETTER_ASSIGN      = 0,
    OBJC_ASSOCIATION_SETTER_RETAIN      = 1,
    OBJC_ASSOCIATION_SETTER_COPY        = 3,            // NOTE:  both bits are set, so we can simply test 1 bit in releaseValue below.
    OBJC_ASSOCIATION_GETTER_READ        = (0 << 8), 
    OBJC_ASSOCIATION_GETTER_RETAIN      = (1 << 8), 
    OBJC_ASSOCIATION_GETTER_AUTORELEASE = (2 << 8)
}; 

// 获取关联对象
id _object_get_associative_reference(id object, void *key) {
    id value = nil;
    uintptr_t policy = OBJC_ASSOCIATION_ASSIGN;
    {
        AssociationsManager manager;
        // 获取到manager中的AssociationsHashMap
        AssociationsHashMap &associations(manager.associations());
        // 获取对象的DISGUISE值
        disguised_ptr_t disguised_object = DISGUISE(object);
        AssociationsHashMap::iterator i = associations.find(disguised_object);
        if (i != associations.end()) {
            // 获取ObjectAssociationMap
            ObjectAssociationMap *refs = i->second;
            ObjectAssociationMap::iterator j = refs->find(key);
            if (j != refs->end()) {
                // 获取到关联对象ObjcAssociation
                ObjcAssociation &entry = j->second;
                // 获取到value
                value = entry.value();
                policy = entry.policy();
                if (policy & OBJC_ASSOCIATION_GETTER_RETAIN) {
                    objc_retain(value);
                }
            }
        }
    }
    if (value && (policy & OBJC_ASSOCIATION_GETTER_AUTORELEASE)) {
        objc_autorelease(value);
    }
    // 返回关联对像的值
    return value;
}

// 根据policy的值，对value进行retain或者copy
static id acquireValue(id value, uintptr_t policy) {
    switch (policy & 0xFF) {
    case OBJC_ASSOCIATION_SETTER_RETAIN:
        return objc_retain(value);
    case OBJC_ASSOCIATION_SETTER_COPY:
        return ((id(*)(id, SEL))objc_msgSend)(value, SEL_copy);
    }
    return value;
}

static void releaseValue(id value, uintptr_t policy) {
    if (policy & OBJC_ASSOCIATION_SETTER_RETAIN) {
        return objc_release(value);
    }
}

struct ReleaseValue {
    void operator() (ObjcAssociation &association) {
        // 根据policy值，释放value
        releaseValue(association.value(), association.policy());
    }
};

// 该方法完成了设置关联对象的操作
void _object_set_associative_reference(id object, void *key, id value, uintptr_t policy) {
    // retain the new value (if any) outside the lock.
    // 初始化空的ObjcAssociation(关联对象)
    ObjcAssociation old_association(0, nil);
    id new_value = value ? acquireValue(value, policy) : nil;
    {
        // 初始化一个manager
        AssociationsManager manager;//单例，内部保存一个全局的static AssociationsHashMap *_map;用于保存所有的关联对象
        AssociationsHashMap &associations(manager.associations());
        // 获取对象的DISGUISE值，作为AssociationsHashMap的key
        disguised_ptr_t disguised_object = DISGUISE(object);//取反对象地址作为accociative key
        if (new_value) {
            // value有值，不为nil
            // break any existing association.
            // AssociationsHashMap::iterator 类型的迭代器
            AssociationsHashMap::iterator i = associations.find(disguised_object);
            if (i != associations.end()) {
                // secondary table exists
                // 获取到ObjectAssociationMap(key是外部传来的key，value是关联对象类ObjcAssociation)
                ObjectAssociationMap *refs = i->second;
                // ObjectAssociationMap::iterator 类型的迭代器
                //迭代器检查容器内元素并遍历元素的数据类型
                ObjectAssociationMap::iterator j = refs->find(key);
                if (j != refs->end()) {
                    // 原来该key对应的有关联对象
                    // 将原关联对象的值存起来，并且赋新值
                    old_association = j->second;
                    j->second = ObjcAssociation(policy, new_value);
                } else {
                    // 无该key对应的关联对象，直接赋值即可
                    // ObjcAssociation(policy, new_value)提供了这样的构造函数
                    (*refs)[key] = ObjcAssociation(policy, new_value);
                }
            } else {
                // create the new association (first time).
                // 执行到这里，说明该对象是第一次添加关联对象
                // 初始化ObjectAssociationMap
                ObjectAssociationMap *refs = new ObjectAssociationMap;
                associations[disguised_object] = refs;
                // 赋值
                (*refs)[key] = ObjcAssociation(policy, new_value);
                // 设置该对象的有关联对象，调用的是setHasAssociatedObjects()方法
                object->setHasAssociatedObjects();
            }
        } else {
            // setting the association to nil breaks the association.
            // value无值，也就是释放一个key对应的关联对象
            AssociationsHashMap::iterator i = associations.find(disguised_object);
            if (i !=  associations.end()) {
                ObjectAssociationMap *refs = i->second;
                ObjectAssociationMap::iterator j = refs->find(key);
                if (j != refs->end()) {
                    old_association = j->second;
                    // 调用erase()方法删除对应的关联对象
                    refs->erase(j);
                }
            }
        }
    }
    // release the old value (outside of the lock).
    // 释放旧的关联对象
    if (old_association.hasValue()) ReleaseValue()(old_association);
}

// 移除对象object的所有关联对象
void _object_remove_assocations(id object) {
    // 声明了一个vector
    vector< ObjcAssociation,ObjcAllocator<ObjcAssociation> > elements;
    {
        AssociationsManager manager;
        AssociationsHashMap &associations(manager.associations());
        // 如果map size为空，直接返回
        if (associations.size() == 0) return;
        // 获取对象的DISGUISE值
        disguised_ptr_t disguised_object = DISGUISE(object);
        AssociationsHashMap::iterator i = associations.find(disguised_object);
        if (i != associations.end()) {
            // copy all of the associations that need to be removed.
            ObjectAssociationMap *refs = i->second;
            for (ObjectAssociationMap::iterator j = refs->begin(), end = refs->end(); j != end; ++j) {
                elements.push_back(j->second);
            }
            // remove the secondary table.
            delete refs;
            associations.erase(i);
        }
    }
    // the calls to releaseValue() happen outside of the lock.
    for_each(elements.begin(), elements.end(), ReleaseValue());
}

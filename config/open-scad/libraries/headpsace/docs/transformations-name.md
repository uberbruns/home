# Hierarchical Naming

These modules manage component names in the context, building a hierarchical path that identifies each part. Names are output when panels are created, enabling material lists and assembly documentation. The hierarchy uses "/" as a separator (e.g., "Cabinet/Shelf/Bottom").

## name()

Sets the context to a single name component, replacing the entire hierarchy.

```openscad
name(name_component) children();
```

**Parameters:**
- `name_component` - Name string to set as the complete context name

**Usage:**

```openscad
name("Cabinet") {
  block(); // Named "Cabinet"
}
```

## push_name()

Appends a name component to the context hierarchy.

```openscad
push_name(name_component) children();
```

**Parameters:**
- `name_component` - Name string to append to hierarchy

**Usage:**

```openscad
name("Cabinet") {
  push_name("Shelf") {
    block(); // Named "Cabinet/Shelf"
    push_name("Support") {
      block(); // Named "Cabinet/Shelf/Support"
    }
  }
}
```

## pop_name()

Removes the last name component from the context hierarchy.

```openscad
pop_name() children();
```

**Usage:**

```openscad
push_name("Cabinet") {
  push_name("Section") {
    push_name("Shelf") {
      pop_name() {
        block(); // Named "Cabinet/Section" (removed "Shelf")
      }
    }
  }
}
```

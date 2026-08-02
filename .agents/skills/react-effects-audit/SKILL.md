---
name: react-effects-audit
description:
  Audit a React component for unnecessary useEffect calls. Use when asked to
  clean up effects, review a component for effect misuse, or decide whether an
  effect belongs in an event handler, can be derived during render, or should
  synchronize only with an external system.
license: MIT
metadata:
  source: https://react.dev/learn/you-might-not-need-an-effect
---

# React Effects Audit

Audit a component's `useEffect` calls. Keep only effects that synchronize React
with an **external system**: the network, browser DOM, non-React widgets, or
mutable stores. Everything else should be removed or moved.

## The Audit

### 1. Inventory every `useEffect`

Read the target component(s) and list every `useEffect` call with:

- its purpose in one sentence
- its dependency array
- whether it calls `setState` or another side effect

Completion criterion: every `useEffect` in scope is listed with purpose and
dependencies.

### 2. Classify each effect

Apply the **external-system test** to each effect:

> Does this run because the component was displayed, in order to keep React in
> sync with something outside React?

If **yes**, label it **KEEP**. Otherwise label it with the nearest misuse:

| Label | When to use |
| ----- | ----------- |
| **KEEP** | Synchronizes with an external system. |
| **HANDLER** | Logic is triggered by a user interaction or event. |
| **DERIVE** | Value can be calculated from props/state during render. |
| **MEMOIZE** | Expensive pure calculation should use `useMemo`. |
| **RESET-KEY** | All child state should reset when a prop changes. |
| **ADJUST** | One state value should reset when a prop changes. |
| **COLLAPSE** | Chain of state updates triggered by one event. |
| **LIFT** | Child notifies parent or siblings share derived state. |
| **ONCE** | Logic should run once per app load, not per mount. |

Completion criterion: every effect is labeled with exactly one audit class.

### 3. Apply replacements

For each non-KEEP effect, rewrite it with the matching pattern below. Make the
smallest change that removes the unnecessary effect and any redundant state it
maintained.

Completion criterion: every non-KEEP effect is removed or rewritten, and no
stale or redundant state remains.

### 4. Verify

Run type checks, lint, and the narrowest relevant tests. Inspect the diff for
unintended behavior changes, especially around event timing, initial render, and
state reset.

Completion criterion: all checks pass and behavior is preserved except for the
intended simplification.

## Replacement Patterns

### HANDLER — Move event logic into an event handler

Effects cannot know which user action caused them. Move logic triggered by
clicks, submits, or drag ends into the corresponding handler.

```js
// Avoid
useEffect(() => {
  if (product.isInCart) showNotification(`Added ${product.name}`);
}, [product]);

// Good
function buyProduct() {
  addToCart(product);
  showNotification(`Added ${product.name}`);
}
function handleBuyClick() { buyProduct(); }
function handleCheckoutClick() { buyProduct(); navigateTo('/checkout'); }
```

Also applies to POST requests that should fire on a specific interaction and to
notifying a parent about state changes in a child.

### DERIVE — Calculate during render

When a value can be computed from existing props or state, derive it during
render. Remove both the effect and the redundant state.

```js
// Avoid
const [fullName, setFullName] = useState('');
useEffect(() => setFullName(firstName + ' ' + lastName), [firstName, lastName]);

// Good
const fullName = firstName + ' ' + lastName;
```

### MEMOIZE — Cache expensive pure calculations

Use `useMemo` for genuinely expensive pure calculations, not state + effect.

```js
const visibleTodos = useMemo(
  () => getFilteredTodos(todos, filter),
  [todos, filter]
);
```

`useMemo` skips updates but does not speed up the first render. Profile before
adding it.

### RESET-KEY — Reset an entire subtree with a `key`

When a prop change should recreate a component and all its children, pass the
prop as a `key`.

```js
function ProfilePage({ userId }) {
  return <Profile key={userId} userId={userId} />;
}
```

Do not reset state for arbitrary prop changes; reserve this for identity-level
changes like switching users or items.

### ADJUST — Set state during render for partial resets

When one state value must track a prop and deriving it is not possible, set it
during render with a previous-render guard.

```js
const [prevItems, setPrevItems] = useState(items);
if (items !== prevItems) {
  setPrevItems(items);
  setSelection(null);
}
```

Only update the same component's state during render. Avoid DOM or timer side
effects.

### COLLAPSE — Move chained state updates into the triggering handler

Chains of effects that each update state to trigger the next cause extra renders
and fragile ordering. Compute all next state in the event handler.

```js
function handlePlaceCard(nextCard) {
  setCard(nextCard);
  if (nextCard.gold) {
    if (goldCardCount < 3) {
      setGoldCardCount(c => c + 1);
    } else {
      setGoldCardCount(0);
      setRound(r => r + 1);
      if (round === 5) alert('Good game!');
    }
  }
}
```

### LIFT — Move data and control up to a common parent

When a child passes data to a parent in an effect, or when two sibling
components keep the same state in sync, let the parent own the data and pass it
down.

```js
// Avoid child fetching then notifying parent
function Child({ onFetched }) {
  const data = useSomeAPI();
  useEffect(() => { if (data) onFetched(data); }, [data, onFetched]);
}

// Good: parent fetches, child receives props
function Parent() {
  const data = useSomeAPI();
  return <Child data={data} />;
}
```

Also applies to toggles: pass `isOn` and `onChange` from the parent instead of
keeping local state and notifying via effect.

### ONCE — Initialize once per app load

Logic that must run once per app load, not per mount, belongs at module level
or behind a module-level guard inside an effect.

```js
let didInit = false;
function App() {
  useEffect(() => {
    if (!didInit) {
      didInit = true;
      init();
    }
  }, []);
}
```

Keep module-level initialization limited to root modules to avoid surprising
import side effects.

## Correct Effects to Leave In Place

Do not remove:

- **Data fetching** that synchronizes visible results with query/page state.
  Use a cleanup `ignore` flag to avoid race conditions. Prefer framework data
  fetching when available.
- **External store subscriptions.** Prefer `useSyncExternalStore`.
- **Synchronization with non-React widgets or browser APIs.**
- **Analytics or logging** that should fire because the component was displayed.

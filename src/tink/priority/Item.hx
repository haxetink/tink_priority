package tink.priority;

typedef Item<T> = {
	data: T,
	?id: ID,
	?before: Selector<T>,
	?after: Selector<T>,
}	
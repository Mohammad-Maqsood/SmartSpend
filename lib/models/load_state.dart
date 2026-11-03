/// The loading status of data that comes from device storage.
///
/// Together with "is the list empty?", this gives the four screen states the
/// list screen must handle: loading, error, empty and data.
enum LoadState { loading, error, loaded }

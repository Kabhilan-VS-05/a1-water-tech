enum SyncResult { success, partial, failed, offline, alreadySyncing }

extension SyncResultExtension on SyncResult {
  String get message {
    switch (this) {
      case SyncResult.success:
        return 'Sync completed successfully';
      case SyncResult.partial:
        return 'Some items failed to sync';
      case SyncResult.failed:
        return 'Sync failed';
      case SyncResult.offline:
        return 'Device offline';
      case SyncResult.alreadySyncing:
        return 'Sync already in progress';
    }
  }
}

# Firebase Wallet Collections Setup Guide

## 📊 Collections to Create

### 1. `wallets` Collection
Stores detailed wallet information for each user.

**Collection Path**: `/wallets`

**Document ID**: `{userId}`

**Document Structure**:
```json
{
  "balance": 500.0,
  "tournament_points": 150,
  "last_updated": "2024-10-15T19:00:00Z",
  "currency": "FLIXBIT",
  "status": "active",
  "account_type": "user",
  "limits": {
    "min_purchase": 100,
    "max_purchase": 10000,
    "daily_earning_cap": 1000
  }
}
```

**Fields**:
- `balance` (number): Current Flixbit points balance
- `tournament_points` (number): Total points earned from tournaments (analytics)
- `last_updated` (timestamp): Last balance update timestamp
- `currency` (string): Currency type (always "FLIXBIT")
- `status` (string): Account status (active, suspended, closed)
- `account_type` (string): Account type (user, seller, admin)
- `limits` (map): Transaction limits

---

### 2. `wallet_transactions` Collection
Stores all wallet transactions with complete details.

**Collection Path**: `/wallet_transactions`

**Document ID**: Auto-generated

**Document Structure**:
```json
{
  "user_id": "user_123",
  "transaction_type": "earn",
  "amount": 10.0,
  "balance_before": 500.0,
  "balance_after": 510.0,
  "source": {
    "type": "tournamentPrediction",
    "reference_id": "match_456",
    "details": {
      "tournamentId": "tour_001",
      "matchId": "match_456",
      "pointsEarned": 10
    }
  },
  "status": "completed",
  "timestamp": "2024-10-15T19:30:00Z",
  "metadata": {
    "description": "Correct prediction: Liverpool vs Chelsea"
  }
}
```

**Fields**:
- `user_id` (string): User ID
- `transaction_type` (string): earn, spend, buy, sell, refund, gift, reward
- `amount` (number): Transaction amount
- `balance_before` (number): Balance before transaction
- `balance_after` (number): Balance after transaction
- `source` (map): Transaction source details
  - `type` (string): Source type (tournamentPrediction, videoAd, etc.)
  - `reference_id` (string): Related document ID
  - `details` (map): Additional source details
- `status` (string): Transaction status (completed, pending, failed, reversed)
- `timestamp` (timestamp): Transaction timestamp
- `metadata` (map): Additional metadata

---

### 3. `wallet_settings` Collection
Stores global wallet configuration (admin-controlled).

**Collection Path**: `/wallet_settings`

**Document ID**: `global`

**Document Structure**:
```json
{
  "point_values": {
    "tournament_prediction": 10,
    "qualification": 50,
    "tournament_win": 500,
    "video_ad": 5,
    "referral": 20,
    "review": 15,
    "qr_scan": 10,
    "daily_login": 5
  },
  "conversion_rates": {
    "flixbit_to_usd": 0.01,
    "tournament_to_flixbit": 5
  },
  "transaction_limits": {
    "min_purchase": 100,
    "max_purchase": 10000,
    "daily_earning_cap": 1000,
    "min_withdrawal": 500
  },
  "platform_fees": {
    "purchase_fee_percent": 2.5,
    "withdrawal_fee_flat": 50
  }
}
```

**Fields**:
- `point_values` (map): Points awarded for different activities
- `conversion_rates` (map): Currency conversion rates
- `transaction_limits` (map): Transaction limits
- `platform_fees` (map): Platform fees configuration

---

## 🔒 Security Rules

Add these rules to your `firestore.rules` file:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isSignedIn() && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Wallets collection
    match /wallets/{userId} {
      // Users can read their own wallet
      allow read: if isSignedIn() && request.auth.uid == userId;
      
      // Only Cloud Functions can write (prevents client-side manipulation)
      allow write: if false;
    }
    
    // Wallet transactions collection
    match /wallet_transactions/{transactionId} {
      // Users can read their own transactions
      allow read: if isSignedIn() && resource.data.user_id == request.auth.uid;
      
      // Only Cloud Functions can write
      allow write: if false;
    }
    
    // Wallet settings collection (admin only)
    match /wallet_settings/{doc} {
      // Anyone can read settings
      allow read: if isSignedIn();
      
      // Only admins can write
      allow write: if isAdmin();
    }
  }
}
```

---

## 📑 Firestore Indexes

Create these composite indexes for optimal query performance:

### Index 1: User Transactions by Timestamp
```
Collection: wallet_transactions
Fields:
  - user_id (Ascending)
  - timestamp (Descending)
```

**CLI Command**:
```bash
firebase firestore:indexes:create \
  --collection-group=wallet_transactions \
  --field=user_id --field-order=ASCENDING \
  --field=timestamp --field-order=DESCENDING
```

### Index 2: User Transactions by Type and Timestamp
```
Collection: wallet_transactions
Fields:
  - user_id (Ascending)
  - transaction_type (Ascending)
  - timestamp (Descending)
```

**CLI Command**:
```bash
firebase firestore:indexes:create \
  --collection-group=wallet_transactions \
  --field=user_id --field-order=ASCENDING \
  --field=transaction_type --field-order=ASCENDING \
  --field=timestamp --field-order=DESCENDING
```

### Index 3: User Transactions by Source and Timestamp
```
Collection: wallet_transactions
Fields:
  - user_id (Ascending)
  - source.type (Ascending)
  - timestamp (Descending)
```

**CLI Command**:
```bash
firebase firestore:indexes:create \
  --collection-group=wallet_transactions \
  --field=user_id --field-order=ASCENDING \
  --field=source.type --field-order=ASCENDING \
  --field=timestamp --field-order=DESCENDING
```

---

## 🚀 Setup Steps

### Step 1: Initialize Collections

Run this in Firebase Console or via script:

```javascript
// Initialize wallet_settings/global with defaults
db.collection('wallet_settings').doc('global').set({
  point_values: {
    tournament_prediction: 10,
    qualification: 50,
    tournament_win: 500,
    video_ad: 5,
    referral: 20,
    review: 15,
    qr_scan: 10,
    daily_login: 5
  },
  conversion_rates: {
    flixbit_to_usd: 0.01,
    tournament_to_flixbit: 5
  },
  transaction_limits: {
    min_purchase: 100,
    max_purchase: 10000,
    daily_earning_cap: 1000,
    min_withdrawal: 500
  },
  platform_fees: {
    purchase_fee_percent: 2.5,
    withdrawal_fee_flat: 50
  }
});
```

### Step 2: Update Security Rules

1. Go to Firebase Console → Firestore Database → Rules
2. Copy the security rules from above
3. Click "Publish"

### Step 3: Create Indexes

**Option A: Via Firebase Console**
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Create each index as specified above

**Option B: Via Firebase CLI**
1. Ensure you have Firebase CLI installed: `npm install -g firebase-tools`
2. Run the CLI commands listed above for each index

### Step 4: Migrate Existing Users (if any)

Run this Cloud Function or script to create wallets for existing users:

```javascript
const admin = require('firebase-admin');
const db = admin.firestore();

async function migrateExistingUsers() {
  const usersSnapshot = await db.collection('users').get();
  
  const batch = db.batch();
  
  usersSnapshot.forEach(userDoc => {
    const userId = userDoc.id;
    const userData = userDoc.data();
    
    // Create wallet document
    const walletRef = db.collection('wallets').doc(userId);
    batch.set(walletRef, {
      balance: userData.flixbitBalance || 0,
      tournament_points: userData.tournamentPointsEarned || 0,
      last_updated: admin.firestore.FieldValue.serverTimestamp(),
      currency: 'FLIXBIT',
      status: 'active',
      account_type: 'user',
      limits: {
        min_purchase: 100,
        max_purchase: 10000,
        daily_earning_cap: 1000
      }
    });
  });
  
  await batch.commit();
  console.log(`Migrated ${usersSnapshot.size} users`);
}

migrateExistingUsers();
```

---

## ✅ Verification Checklist

After setup, verify:

- [ ] `wallets` collection exists
- [ ] `wallet_transactions` collection exists
- [ ] `wallet_settings/global` document exists with correct structure
- [ ] Security rules are published
- [ ] All 3 indexes are created and status is "Enabled"
- [ ] Test wallet creation works (create a new user)
- [ ] Test transaction creation works (award points)
- [ ] Test wallet read permissions (user can read their own wallet)
- [ ] Test wallet write permissions (user cannot write directly)
- [ ] Test settings read works
- [ ] Test settings write is admin-only

---

## 🔍 Testing Queries

Test these queries in Firebase Console or code:

```javascript
// Get user's wallet
db.collection('wallets')
  .doc(userId)
  .get();

// Get user's recent transactions
db.collection('wallet_transactions')
  .where('user_id', '==', userId)
  .orderBy('timestamp', 'desc')
  .limit(50)
  .get();

// Get user's earned transactions
db.collection('wallet_transactions')
  .where('user_id', '==', userId)
  .where('transaction_type', '==', 'earn')
  .orderBy('timestamp', 'desc')
  .get();

// Get tournament-related transactions
db.collection('wallet_transactions')
  .where('user_id', '==', userId)
  .where('source.type', '==', 'tournamentPrediction')
  .orderBy('timestamp', 'desc')
  .get();

// Get wallet settings
db.collection('wallet_settings')
  .doc('global')
  .get();
```

---

## 📊 Monitoring & Maintenance

### Regular Checks:
1. Monitor transaction counts
2. Check for failed transactions
3. Review pending withdrawals
4. Audit balance consistency
5. Monitor daily earning caps

### Cleanup Scripts:
```javascript
// Find transactions older than 1 year
db.collection('wallet_transactions')
  .where('timestamp', '<', oneYearAgo)
  .get();

// Find pending transactions older than 30 days
db.collection('wallet_transactions')
  .where('status', '==', 'pending')
  .where('timestamp', '<', thirtyDaysAgo)
  .get();
```

---

## 🎯 Post-Setup Tasks

1. **Test Buy Flow**
   - Create test purchase
   - Verify transaction created
   - Verify balance updated
   - Verify notification sent

2. **Test Sell Flow**
   - Create test withdrawal
   - Verify transaction created (pending)
   - Verify balance deducted
   - Verify notification sent

3. **Test Tournament Integration**
   - Award tournament points
   - Verify transaction created
   - Verify balance updated
   - Verify tournament_points tracking updated

4. **Load Testing**
   - Test concurrent transactions
   - Verify balance consistency
   - Check index performance
   - Monitor query times

---

## 📝 Notes

- All wallet operations should go through Cloud Functions or trusted server code
- Never allow client-side balance modifications
- Always create transaction records for audit trail
- Regularly backup wallet and transaction data
- Monitor for suspicious transaction patterns
- Implement rate limiting for transactions
- Consider implementing transaction rollback mechanisms
- Keep settings configurable for easy adjustments

---

## 🆘 Troubleshooting

### Issue: Index not working
**Solution**: Wait 5-10 minutes after creating indexes. Check index status in Firebase Console.

### Issue: Permission denied
**Solution**: Verify security rules are published. Check user authentication status.

### Issue: Balance mismatch
**Solution**: Recalculate balance from transaction history. Implement balance reconciliation script.

### Issue: Slow queries
**Solution**: Ensure all required indexes are created. Consider pagination for large result sets.

---

## 🔗 Related Documentation

- [FlixbitPointsManager Service](lib/src/service/flixbit_points_manager.dart)
- [WalletService](lib/src/service/wallet_service.dart)
- [WalletProvider](lib/src/providers/wallet_provider.dart)
- [Wallet Models](lib/src/models/wallet_models.dart)
- [Implementation Guide](WALLET_IMPLEMENTATION_COMPLETE.md)


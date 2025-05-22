const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Shared handler for status change notifications.
 * @param {Change<DocumentSnapshot>} change - Firestore document change.
 * @param {EventContext} context - Event context.
 * @param {string|null} userIdField - Field name for userId in document data (or null if userId from path).
 * @param {string|null} userIdFromPath - UserId from Firestore path param if applicable.
 */
async function handleStatusChange(change, context, userIdField = 'userId', userIdFromPath = null) {
  const before = change.before.data();
  const after = change.after.data();

  if (!before || !after) return null;

  // Check if status changed and is one of the statuses to notify
  if (before.status !== after.status &&
      (after.status === 'accepted' || after.status === 'rejected' || after.status === 'shortlisted')) {
    
    // Determine userId
    const userId = userIdFromPath || after[userIdField];
    if (!userId) {
      console.log('No userId found in document or path');
      return null;
    }

    // Fetch user document to get device token
    const userDoc = await admin.firestore().collection('Users').doc(userId).get();
    if (!userDoc.exists) {
      console.log('User document does not exist:', userId);
      return null;
    }

    const token = userDoc.data()?.deviceToken;
    if (!token) {
      console.log('No device token for user:', userId);
      return null;
    }

    const statusText = after.status;

    // Compose notification payload
    const payload = {
      notification: {
        title: `Application ${statusText.charAt(0).toUpperCase() + statusText.slice(1)}`,
        body: `Your application for "${after.title || after.jobTitle || 'a job'}" at ${after.companyName || 'the company'} was ${statusText}.`,
      },
      data: {
        type: 'application_status',
        status: statusText,
        jobId: after.jobId || context.params.jobId || '',
        applicationId: context.params.applicationId || context.params.jobId,
      },
    };

    try {
      console.log('Sending notification to token:', token);
      await admin.messaging().sendToDevice(token, payload);
      console.log('Notification sent to user:', userId);
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  }
  return null;
}

// Trigger on application status update in /jobs/{jobId}/applications/{applicationId}
exports.notifyOnJobsApplicationsUpdate = functions.firestore
  .document('jobs/{jobId}/applications/{applicationId}')
  .onUpdate((change, context) => handleStatusChange(change, context, 'userId'));

// Trigger on application status update in /Users/{userId}/appliedjobs/{jobId}
exports.notifyOnUsersAppliedJobsUpdate = functions.firestore
  .document('Users/{userId}/appliedjobs/{jobId}')
  .onUpdate((change, context) => handleStatusChange(change, context, null, context.params.userId));

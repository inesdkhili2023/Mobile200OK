# EmailJS Configuration Guide

This guide will help you configure EmailJS to send verification emails for password reset functionality.

## Step 1: Create an EmailJS Account

1. Go to [https://www.emailjs.com/](https://www.emailjs.com/)
2. Sign up for a free account (200 emails/month free)
3. Verify your email address

## Step 2: Add Email Service

1. Log in to your EmailJS dashboard
2. Go to **Email Services** section
3. Click **Add New Service**
4. Choose your email provider (Gmail, Outlook, etc.)
5. Follow the instructions to connect your email account
6. Note down your **Service ID** (e.g., `service_xxxxxxx`)

## Step 3: Create Email Template

1. Go to **Email Templates** section
2. Click **Create New Template**
3. Use the following template:

**Subject:**
```
Password Reset Verification Code
```

**Content (HTML):**
```html
<h2>Password Reset Verification Code</h2>
<p>Hello {{user_name}},</p>
<p>You have requested to reset your password. Please use the following verification code:</p>
<h3 style="background-color: #f0f0f0; padding: 15px; text-align: center; font-size: 24px; letter-spacing: 5px; border-radius: 5px;">
  {{verification_code}}
</h3>
<p>This code will expire in 10 minutes.</p>
<p>If you didn't request this, please ignore this email.</p>
<p>Best regards,<br>Your App Team</p>
```

4. Save the template
5. Note down your **Template ID** (e.g., `template_xxxxxxx`)

## Step 4: Get Your Public Key

1. Go to **Account** → **General**
2. Find your **Public Key** (also called User ID)
3. Copy it (e.g., `xxxxxxxxxxxxxxxxxx`)

## Step 5: Configure the App

1. Open `lib/services/email_service.dart`
2. Replace the placeholder values:

```dart
static const String _serviceId = 'YOUR_SERVICE_ID'; // Replace with your Service ID
static const String _templateId = 'YOUR_TEMPLATE_ID'; // Replace with your Template ID
static const String _publicKey = 'YOUR_PUBLIC_KEY'; // Replace with your Public Key
```

**Example:**
```dart
static const String _serviceId = 'service_abc123';
static const String _templateId = 'template_xyz789';
static const String _publicKey = 'user_abcdefghijklmnop';
```

## Step 6: Test the Configuration

1. Run your Flutter app
2. Go to "Forgot Password" page
3. Enter a registered email address
4. Click "Send Verification Code"
5. Check the email inbox for the verification code

## Template Variables

The following variables are available in your EmailJS template:
- `{{user_email}}` - User's email address
- `{{user_name}}` - User's full name
- `{{verification_code}}` - 6-digit verification code
- `{{to_email}}` - Recipient email (same as user_email)

## Troubleshooting

### Emails not being sent
1. Check that all three values (Service ID, Template ID, Public Key) are correctly set
2. Verify your email service is connected in EmailJS dashboard
3. Check EmailJS dashboard for error logs
4. Ensure you haven't exceeded the free tier limit (200 emails/month)

### Code not received
1. Check spam/junk folder
2. Verify the email address is correct
3. Check EmailJS dashboard for delivery status
4. Make sure the template variables match ({{verification_code}}, etc.)

### Testing without EmailJS
If EmailJS is not configured, the app will show the verification code in a dialog for testing purposes. This is useful for development but should not be used in production.

## Security Notes

- The Public Key is safe to expose in client-side code
- Never share your Private Key (not used in this implementation)
- EmailJS free tier is suitable for development and small apps
- For production apps with high volume, consider upgrading to a paid plan

## Additional Resources

- [EmailJS Documentation](https://www.emailjs.com/docs/)
- [EmailJS API Reference](https://www.emailjs.com/docs/rest-api/send/)
- [EmailJS Templates Guide](https://www.emailjs.com/docs/user-guide/creating-email-templates/)





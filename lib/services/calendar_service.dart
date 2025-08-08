// lib/services/calendar_service.dart

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';

class CalendarService {
  /// Export event to device calendar
  static Future<bool> exportToCalendar(Event event) async {
    try {
      // For Android/iOS, we'll use the device's calendar app via URL scheme
      final calendarUrl = _generateCalendarUrl(event);
      
      if (await canLaunchUrl(Uri.parse(calendarUrl))) {
        await launchUrl(Uri.parse(calendarUrl));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Generate calendar URL for the event
  static String _generateCalendarUrl(Event event) {
    final startDate = event.startDate;
    final endDate = event.endDate ?? startDate.add(const Duration(hours: 1));
    
    // Format dates for calendar URL (YYYYMMDDTHHMMSSZ)
    final startFormatted = _formatDateForCalendar(startDate);
    final endFormatted = _formatDateForCalendar(endDate);
    
    // Encode event details
    final title = Uri.encodeComponent(event.title);
    final description = Uri.encodeComponent(event.description);
    final location = Uri.encodeComponent(event.location);
    
    // Google Calendar URL format
    return 'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=$title'
        '&dates=$startFormatted/$endFormatted'
        '&details=$description'
        '&location=$location'
        '&sf=true'
        '&output=xml';
  }

  /// Format DateTime for calendar URL
  static String _formatDateForCalendar(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}'
        'T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}'
        'Z';
  }

  /// Generate ICS file content for the event
  static String generateICSContent(Event event) {
    final startDate = event.startDate;
    final endDate = event.endDate ?? startDate.add(const Duration(hours: 1));
    
    final startFormatted = _formatDateForICS(startDate);
    final endFormatted = _formatDateForICS(endDate);
    final createdFormatted = _formatDateForICS(DateTime.now());
    
    return '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Community Beat//Event Calendar//EN
BEGIN:VEVENT
UID:${event.id}@communitybeat.app
DTSTAMP:$createdFormatted
DTSTART:$startFormatted
DTEND:$endFormatted
SUMMARY:${_escapeICSText(event.title)}
DESCRIPTION:${_escapeICSText(event.description)}
LOCATION:${_escapeICSText(event.location)}
ORGANIZER:CN=${_escapeICSText(event.organizer)}
STATUS:CONFIRMED
TRANSP:OPAQUE
END:VEVENT
END:VCALENDAR''';
  }

  /// Format DateTime for ICS file
  static String _formatDateForICS(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}'
        'T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}'
        'Z';
  }

  /// Escape text for ICS format
  static String _escapeICSText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  /// Copy event details to clipboard
  static Future<void> copyEventToClipboard(Event event) async {
    final eventText = '''
${event.title}

📅 ${_formatEventDate(event.startDate)}${event.endDate != null ? ' - ${_formatEventDate(event.endDate!)}' : ''}
📍 ${event.location}
👤 Organized by ${event.organizer}

${event.description}

${event.tags.isNotEmpty ? '\nTags: ${event.tags.join(', ')}' : ''}
''';

    await Clipboard.setData(ClipboardData(text: eventText));
  }

  /// Format date for display
  static String _formatEventDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $period';
  }

  /// Share event as text
  static String generateShareText(Event event) {
    return '''
🎉 ${event.title}

${event.description}

📅 ${_formatEventDate(event.startDate)}${event.endDate != null ? ' - ${_formatEventDate(event.endDate!)}' : ''}
📍 ${event.location}
👤 Organized by ${event.organizer}

${event.contactInfo != null ? '📞 Contact: ${event.contactInfo}' : ''}
${event.ticketPrice != null ? '💰 ${event.ticketPrice == 0 ? 'Free Event' : 'Price: \$${event.ticketPrice!.toStringAsFixed(2)}'}' : ''}
${event.maxAttendees != null ? '👥 Limited to ${event.maxAttendees} attendees' : ''}

#CommunityBeat #${event.category.replaceAll(' ', '')} ${event.tags.map((tag) => '#${tag.replaceAll(' ', '')}').join(' ')}
''';
  }

  /// Get calendar app suggestions based on platform
  static List<CalendarApp> getAvailableCalendarApps() {
    return [
      CalendarApp(
        name: 'Google Calendar',
        icon: '📅',
        description: 'Add to Google Calendar',
      ),
      CalendarApp(
        name: 'Apple Calendar',
        icon: '🍎',
        description: 'Add to Apple Calendar',
      ),
      CalendarApp(
        name: 'Outlook',
        icon: '📧',
        description: 'Add to Outlook Calendar',
      ),
      CalendarApp(
        name: 'Copy Details',
        icon: '📋',
        description: 'Copy event details to clipboard',
      ),
    ];
  }
}

class CalendarApp {
  final String name;
  final String icon;
  final String description;

  CalendarApp({
    required this.name,
    required this.icon,
    required this.description,
  });
}
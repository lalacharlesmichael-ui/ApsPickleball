from __future__ import annotations

import html
import re
from datetime import datetime, timezone
from pathlib import Path
from textwrap import wrap
from zipfile import ZIP_DEFLATED, ZipFile

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
IMAGES = DOCS / "guide_images"
MD_PATH = DOCS / "Aps_Pickle_Zone_User_Guide.md"
DOCX_PATH = DOCS / "Aps_Pickle_Zone_User_Guide.docx"

GREEN = "#5BEA7E"
DARK = "#061018"
PANEL = "#111B24"
CARD = "#1B2530"
CARD_2 = "#25313B"
TEXT = "#F1F7F3"
MUTED = "#A7B4BE"
AMBER = "#F4B63F"
BLUE = "#83CAFF"
RED = "#FF2F2F"
WHITE = "#FFFFFF"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
        Path("C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


FONT = font(24)
FONT_BOLD = font(24, True)
FONT_SMALL = font(18)
FONT_SMALL_BOLD = font(18, True)
FONT_TITLE = font(38, True)
FONT_SECTION = font(30, True)


def rounded(draw: ImageDraw.ImageDraw, xy, fill, outline=None, width=1, radius=16):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def text(draw: ImageDraw.ImageDraw, xy, value: str, fill=TEXT, fnt=FONT, max_width: int | None = None, line_gap=6):
    x, y = xy
    if max_width is None:
        draw.text((x, y), value, fill=fill, font=fnt)
        return
    words = value.split()
    lines: list[str] = []
    current = ""
    for word in words:
        trial = f"{current} {word}".strip()
        if draw.textlength(trial, font=fnt) <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    for line in lines:
        draw.text((x, y), line, fill=fill, font=fnt)
        y += fnt.size + line_gap


def button(draw, xy, label, fill=GREEN, fg=DARK, w=180, h=48):
    x, y = xy
    rounded(draw, (x, y, x + w, y + h), fill=fill, radius=12)
    tw = draw.textlength(label, font=FONT_SMALL_BOLD)
    draw.text((x + (w - tw) / 2, y + 13), label, fill=fg, font=FONT_SMALL_BOLD)
    return (x, y, x + w, y + h)


def outline(draw, xy, label: str, label_xy=None):
    x1, y1, x2, y2 = xy
    draw.rounded_rectangle((x1 - 8, y1 - 8, x2 + 8, y2 + 8), radius=18, outline=RED, width=6)
    if label_xy is not None:
        lx, ly = label_xy
        rounded(draw, (lx, ly, lx + 330, ly + 58), fill=WHITE, outline=RED, width=3, radius=12)
        draw.text((lx + 14, ly + 15), label, fill=RED, font=FONT_SMALL_BOLD)
        draw.line((lx + 12, ly + 29, (x1 + x2) / 2, (y1 + y2) / 2), fill=RED, width=4)


def base(title: str, subtitle: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (1280, 820), DARK)
    draw = ImageDraw.Draw(img)
    rounded(draw, (26, 24, 1254, 796), fill=PANEL, outline="#263542", radius=22)
    text(draw, (56, 46), title, fnt=FONT_TITLE)
    text(draw, (58, 92), subtitle, fill=MUTED, fnt=FONT_SMALL)
    return img, draw


def nav(draw, selected: str):
    items = ["Dashboard", "Progress", "Book", "Schedule", "Bookings", "Notifications", "Profile"]
    y = 150
    for item in items:
        fill = "#183825" if item == selected else PANEL
        fg = GREEN if item == selected else MUTED
        rounded(draw, (58, y, 224, y + 46), fill=fill, radius=12)
        draw.text((76, y + 13), item, fill=fg, font=FONT_SMALL_BOLD)
        y += 56


def card(draw, xy, title=None):
    rounded(draw, xy, fill=CARD, outline="#263542", radius=16)
    if title:
        text(draw, (xy[0] + 22, xy[1] + 18), title, fnt=FONT_BOLD)


def draw_customer_dashboard():
    img, draw = base("Customer Dashboard", "Quick progress, booking shortcut, and recent activity.")
    nav(draw, "Dashboard")
    card(draw, (260, 140, 760, 396), "Hello, Player!")
    text(draw, (286, 196), "Your monthly progress", fnt=FONT_SMALL_BOLD)
    rounded(draw, (286, 236, 680, 258), fill="#31414B", radius=10)
    rounded(draw, (286, 236, 590, 258), fill=GREEN, radius=10)
    text(draw, (286, 280), "Productivity 80%    Court Hours 14h", fill=WHITE, fnt=FONT_SMALL)
    book_btn = button(draw, (286, 322), "Book a Court", w=180)
    card(draw, (790, 140, 1160, 396), "Monthly Activity")
    for row in range(4):
        for col in range(7):
            x, y = 818 + col * 44, 198 + row * 42
            fill = GREEN if (row + col) % 3 != 0 else CARD_2
            rounded(draw, (x, y, x + 32, y + 32), fill=fill, radius=8)
    card(draw, (260, 430, 710, 706), "Upcoming Bookings")
    text(draw, (286, 492), "Court 1 - July 10, 2026 - 8:00 PM", fnt=FONT_SMALL)
    card(draw, (742, 430, 1160, 706), "Notifications")
    text(draw, (768, 492), "Admin message content appears here.", fnt=FONT_SMALL, max_width=330)
    outline(draw, book_btn, "1. Book from here", (850, 316))
    outline(draw, (742, 430, 1160, 706), "2. Check new messages", (826, 718))
    img.save(IMAGES / "01_customer_dashboard.png")


def draw_book_court():
    img, draw = base("Book a Court", "Choose court, date, start time, duration, then submit.")
    nav(draw, "Book")
    card(draw, (300, 150, 1030, 710), "Booking Form")
    fields = [
        ("Court", "Court 1 - PHP 250/hr"),
        ("Date", "July 10, 2026"),
        ("Start time", "10:00 PM"),
        ("Duration", "1 hour"),
    ]
    rects = []
    y = 220
    for label, value in fields:
        text(draw, (330, y - 26), label, fill=MUTED, fnt=FONT_SMALL_BOLD)
        rounded(draw, (330, y, 980, y + 54), fill=CARD_2, outline="#3A4B58", radius=12)
        text(draw, (350, y + 15), value, fnt=FONT_SMALL_BOLD)
        rects.append((330, y, 980, y + 54))
        y += 92
    rounded(draw, (330, 590, 980, 642), fill="#183825", radius=12)
    text(draw, (350, 604), "This slot is available. Total amount: PHP 250.00", fill=GREEN, fnt=FONT_SMALL_BOLD)
    submit = button(draw, (330, 662), "Submit Booking Request", w=260)
    outline(draw, rects[2], "1. Pick start time", (842, 340))
    outline(draw, rects[3], "2. Pick hours", (842, 432))
    outline(draw, submit, "3. Submit request", (650, 662))
    img.save(IMAGES / "02_book_court.png")


def draw_booking_payment():
    img, draw = base("Bookings and Payment Proof", "Track status, open receipt, and upload proof.")
    nav(draw, "Bookings")
    card(draw, (278, 150, 690, 700), "My Bookings")
    booking = (304, 224, 658, 306)
    rounded(draw, booking, fill=CARD_2, radius=12)
    text(draw, (326, 242), "APZ-1001 - Court 1", fnt=FONT_SMALL_BOLD)
    text(draw, (326, 270), "Pending - PHP 250.00", fill=MUTED, fnt=FONT_SMALL)
    card(draw, (730, 150, 1164, 700), "Booking Details")
    text(draw, (758, 220), "Payment Proof", fnt=FONT_BOLD)
    proof = button(draw, (758, 280), "Choose JPG, PNG, or PDF", fill=CARD_2, fg=WHITE, w=270)
    upload = button(draw, (758, 348), "Upload Proof", w=170)
    print_btn = button(draw, (958, 220), "Print Receipt", fill=CARD_2, fg=WHITE, w=160)
    outline(draw, booking, "1. Open booking", (406, 336))
    outline(draw, proof, "2. Choose file", (942, 312))
    outline(draw, upload, "3. Upload proof", (942, 384))
    outline(draw, print_btn, "Receipt option", (900, 156))
    img.save(IMAGES / "03_booking_payment.png")


def draw_notifications():
    img, draw = base("Client Notifications", "Admin messages display as readable content cards.")
    nav(draw, "Notifications")
    mark = button(draw, (920, 96), "Mark All Read", fill=CARD_2, fg=WHITE, w=170)
    card(draw, (300, 170, 1070, 660), "Message from Admin")
    text(draw, (334, 244), "Court Reminder", fnt=FONT_BOLD)
    text(draw, (334, 286), "Message from admin - July 7, 2026 6:30 PM", fill=MUTED, fnt=FONT_SMALL)
    text(draw, (334, 348), "Please arrive 10 minutes before your approved booking time. Bring your payment receipt and check in at the desk.", fnt=FONT, max_width=650)
    check = button(draw, (846, 560), "Mark Read", w=150)
    outline(draw, (300, 170, 1070, 660), "Admin message content", (792, 250))
    outline(draw, check, "Clear unread", (770, 642))
    outline(draw, mark, "All read", (890, 42))
    img.save(IMAGES / "04_notifications.png")


def draw_profile():
    img, draw = base("Profile Update", "Update contact details and profile image.")
    nav(draw, "Profile")
    card(draw, (340, 150, 990, 708), "Profile")
    draw.ellipse((598, 214, 714, 330), fill="#183825", outline=GREEN, width=4)
    text(draw, (636, 252), "AP", fnt=FONT_SECTION, fill=GREEN)
    change = button(draw, (528, 350), "Change Profile Photo", fill=CARD_2, fg=WHITE, w=260)
    fields = [("Full name", "Player Name"), ("Username", "@player"), ("Contact number", "0917 000 0000")]
    y = 432
    for label, value in fields:
        text(draw, (388, y - 22), label, fill=MUTED, fnt=FONT_SMALL)
        rounded(draw, (388, y, 940, y + 50), fill=CARD_2, radius=12)
        text(draw, (410, y + 14), value, fnt=FONT_SMALL_BOLD)
        y += 74
    save = button(draw, (388, 654), "Save Profile", w=190)
    outline(draw, (598, 214, 714, 330), "Photo preview", (782, 216))
    outline(draw, change, "Choose image", (790, 348))
    outline(draw, save, "Save changes", (622, 648))
    img.save(IMAGES / "05_profile_update.png")


def draw_admin_bookings():
    img, draw = base("Admin Booking Review", "Approve, decline, cancel, or complete reservations.")
    nav(draw, "Dashboard")
    card(draw, (270, 150, 710, 690), "Recent Booking Requests")
    req = (300, 238, 680, 326)
    rounded(draw, req, fill=CARD_2, radius=12)
    text(draw, (322, 254), "APZ-1001 - Customer Name", fnt=FONT_SMALL_BOLD)
    text(draw, (322, 282), "Court 1 - Pending", fill=MUTED, fnt=FONT_SMALL)
    card(draw, (750, 150, 1166, 690), "Booking Details")
    approve = button(draw, (790, 300), "Approve", w=130)
    decline = button(draw, (940, 300), "Decline", fill=CARD_2, fg=WHITE, w=130)
    complete = button(draw, (790, 372), "Complete", fill=CARD_2, fg=WHITE, w=150)
    outline(draw, req, "1. Select request", (380, 352))
    outline(draw, approve, "2. Approve paid booking", (908, 234))
    outline(draw, decline, "Decline with note", (916, 390))
    outline(draw, complete, "Mark completed", (616, 388))
    img.save(IMAGES / "06_admin_bookings.png")


def draw_admin_customers():
    img, draw = base("Admin Customer Messages", "Send direct messages and view customer photos.")
    nav(draw, "Customers")
    card(draw, (260, 150, 700, 686), "Customer Card")
    draw.ellipse((304, 224, 366, 286), fill="#183825", outline=GREEN, width=3)
    text(draw, (384, 226), "Customer Name", fnt=FONT_BOLD)
    text(draw, (384, 260), "@customer - 0917 000 0000", fill=MUTED, fnt=FONT_SMALL)
    notify = button(draw, (500, 330), "Notify", w=130)
    card(draw, (744, 150, 1166, 686), "Notify Customer")
    title = (780, 236, 1128, 290)
    msg = (780, 326, 1128, 456)
    rounded(draw, title, fill=CARD_2, radius=12)
    text(draw, (800, 252), "Title", fill=MUTED, fnt=FONT_SMALL)
    rounded(draw, msg, fill=CARD_2, radius=12)
    text(draw, (800, 344), "Message", fill=MUTED, fnt=FONT_SMALL)
    send = button(draw, (980, 504), "Send", w=120)
    outline(draw, (304, 224, 366, 286), "Customer photo", (416, 178))
    outline(draw, notify, "1. Open notify", (360, 400))
    outline(draw, title, "2. Add title", (888, 184))
    outline(draw, msg, "3. Add message", (904, 460))
    outline(draw, send, "4. Send to client", (812, 564))
    img.save(IMAGES / "07_admin_customers_notify.png")


def draw_reports_maintenance():
    img, draw = base("Reports and Maintenance", "Review income and block unavailable court time.")
    nav(draw, "Reports")
    card(draw, (270, 150, 700, 690), "Reports")
    for i, label in enumerate(["Daily Income", "Weekly Income", "Monthly Income", "Most Rented Court"]):
        x, y = 304, 224 + i * 78
        rounded(draw, (x, y, 650, y + 54), fill=CARD_2, radius=12)
        text(draw, (326, y + 16), label, fnt=FONT_SMALL_BOLD)
    card(draw, (740, 150, 1166, 690), "Maintenance")
    fields = [("Court", 226), ("Date", 304), ("Start time", 382), ("Reason", 460)]
    rects = []
    for label, y in fields:
        rounded(draw, (780, y, 1126, y + 52), fill=CARD_2, radius=12)
        text(draw, (802, y + 15), label, fill=MUTED, fnt=FONT_SMALL_BOLD)
        rects.append((780, y, 1126, y + 52))
    sched = button(draw, (780, 560), "Schedule Maintenance", w=250)
    outline(draw, (270, 150, 700, 690), "Review performance", (374, 712))
    outline(draw, rects[0], "Choose court", (900, 172))
    outline(draw, sched, "Block court time", (834, 626))
    img.save(IMAGES / "08_reports_maintenance.png")


def build_images():
    IMAGES.mkdir(parents=True, exist_ok=True)
    draw_customer_dashboard()
    draw_book_court()
    draw_booking_payment()
    draw_notifications()
    draw_profile()
    draw_admin_bookings()
    draw_admin_customers()
    draw_reports_maintenance()


GUIDE = r"""# Aps Pickle Zone User Guide

Version: 1.1

This guide is a step-by-step manual for customers, admins, and system owners. Red circles in the interface images show the exact button, field, or content area to use.

## 1. Overview

Aps Pickle Zone is a dynamic web app for pickleball court reservations and court operations. Customers can register, book courts, upload payment proof, track personal progress, receive notifications, and manage their profile. Admin users can approve bookings, manage courts, send customer notifications, track active rentals, review reports, and manage maintenance.

The app is designed as an installable web app. It can be opened in a browser and installed from supported browsers as a standalone app.

## 2. User Roles

### Customer

Customers can:

- Create an account and log in.
- Book available pickleball courts.
- Upload payment proof.
- Track booking status and receipts.
- View availability schedules.
- Receive booking and admin notifications.
- Track personal progress, court hours, streaks, and productivity.
- Update profile details and profile photo.
- View leaderboard rankings.

### Admin

Admins can:

- Review and approve or decline booking requests.
- Verify payment proof.
- Manage customer profiles.
- Send direct notifications to customers.
- View customer profile photos.
- Manage court availability and maintenance.
- Monitor active rentals with live countdowns.
- Review revenue reports and booking summaries.
- View activity logs.

## 3. Visual Step-by-Step Customer Guide

### Customer Dashboard

![Annotated customer dashboard](guide_images/01_customer_dashboard.png)

1. Select Book a Court to create a new reservation.
2. Check recent admin messages and booking updates in Notifications.
3. Use Dashboard and Progress to monitor court hours, streaks, and productivity.

### Book a Court

![Annotated booking form](guide_images/02_book_court.png)

1. Select the court, date, start time, and duration.
2. Confirm the slot is available.
3. Select Submit Booking Request.

Booking rules:

- Court rate is PHP 250.00 per hour.
- Default maximum booking duration is 4 hours.
- Bookings can run up to 11:00 PM.
- Pending, approved, and active bookings block overlapping reservations.
- Maintenance blocks prevent booking affected courts.

### Bookings and Payment Proof

![Annotated booking and payment proof screen](guide_images/03_booking_payment.png)

1. Open Bookings.
2. Select the booking row.
3. Choose a JPG, PNG, or PDF payment proof.
4. Select Upload Proof.
5. Use Print Receipt when the booking is billable.

Payment proof files must be 8 MB or smaller.

### Client Notifications

![Annotated client notifications](guide_images/04_notifications.png)

1. Open Notifications to view booking updates and admin messages.
2. Admin messages appear as full content cards.
3. Use Mark Read or Mark All Read to clear unread indicators.

### Profile Update

![Annotated profile update screen](guide_images/05_profile_update.png)

1. Open Profile.
2. Select Change Profile Photo to choose a JPG or PNG image.
3. Edit full name or contact number if needed.
4. Select Save Profile.

Profile photos must be 15 MB or smaller. The image preview updates immediately after selection and after saving.

## 4. Visual Step-by-Step Admin Guide

### Admin Booking Review

![Annotated admin booking review](guide_images/06_admin_bookings.png)

1. Open Bookings or select a recent request from the Admin Dashboard.
2. Review the booking details and payment proof.
3. Select Approve for valid paid bookings.
4. Select Decline or Cancel when needed and include an admin note.
5. Select Complete when the rental is finished.

### Customer Management and Direct Messages

![Annotated admin customer notification](guide_images/07_admin_customers_notify.png)

1. Open Customers.
2. Review customer profile photos, contact details, bookings, and payments.
3. Select Notify.
4. Add a title and message.
5. Select Send.

The message appears in the customer's Notifications page as a full admin message card.

### Reports and Maintenance

![Annotated reports and maintenance](guide_images/08_reports_maintenance.png)

1. Open Reports to review income, top renters, most rented court, and booking status summaries.
2. Open Maintenance to block court time for repairs or private events.
3. Select court, date, time, duration, and reason.
4. Select Schedule Maintenance.

Maintenance blocks prevent new bookings in the affected time range.

## 5. Accessing the App

1. Open the web app URL provided by the owner or deployment host.
2. Use the navigation menu to go to Login or Register.
3. On mobile, open the side menu from the app bar.
4. On supported browsers, install the app from the browser install prompt or menu.

## 6. Customer Reference

### Register an Account

1. Open Register.
2. Enter full name, username, contact number, and password.
3. Select Create Account.
4. After registration, log in using the username and password.

Usernames must use lowercase letters, numbers, dots, dashes, or underscores.

### Log In

1. Open Login.
2. Enter username and password.
3. Select Login.

If login fails, confirm the account exists and that Supabase email confirmation is disabled or the account has been confirmed by the owner.

### Track Bookings

Open Bookings to see:

- Booking reference.
- Court and date.
- Time range.
- Total amount.
- Payment status.
- Booking status.
- Receipt and print option when billable.

Statuses include Pending, Approved, Active, Completed, Cancelled, and Declined.

### View Court Availability

Open Schedule to view court availability by date. Green slots are open. Busy, maintenance, or closed slots cannot be booked.

### Personal Progress

Open Progress to track:

- Productivity score.
- Monthly court goal.
- Weekly and monthly hours.
- Active days.
- Current and best streaks.
- Completed sessions.
- Verified spend.
- Favorite court.

## 7. Admin Reference

### Admin Dashboard

The Admin Dashboard shows:

- Total customers.
- Pending booking requests.
- Approved bookings today.
- Active renters.
- Available courts.
- Total income.
- Recent booking requests.
- Active rental countdowns.
- Player of the Week.

### Court Management

Open Courts to:

- Set a court as Available.
- Mark a court for Maintenance.
- Mark a court as Inactive.
- Add maintenance or status notes.

### Active Rentals

Open Active to see live countdown timers for rentals currently in play. Timers update smoothly without requiring manual refresh.

### Activity Logs

Open Logs to review important admin actions.

## 8. Real-Time Behavior

The app uses Supabase Realtime for key data updates. Booking changes, notifications, court updates, maintenance changes, profile changes, and admin activity updates refresh quietly in the background.

The app also reduces unnecessary full-screen refreshes. Countdown timers update locally, while data changes are debounced to avoid repeated reloads.

## 9. Setup Notes for Owners

### Supabase Setup

Run the main schema in Supabase SQL Editor:

```sql
supabase/schema.sql
```

For existing installations, also run:

```sql
supabase/username_only_profiles_patch.sql
supabase/profile_image_bucket_limit_patch.sql
```

The profile image patch raises the private profile image bucket limit to 15 MB.

### Environment Variables

Set these values in the deployment host:

- SUPABASE_URL
- SUPABASE_ANON_KEY

For local IDE testing, these can also be set in:

```text
assets/config/supabase.json
```

### Build the Web App

Use:

```powershell
C:\flutter\bin\flutter.bat build web --release
```

Deploy the generated folder:

```text
build/web
```

Supported hosts include Vercel, Netlify, Firebase Hosting, and other static hosts.

## 10. Troubleshooting

### Profile Photo Does Not Upload

Confirm the file is JPG or PNG and 15 MB or smaller. For existing Supabase projects, run `supabase/profile_image_bucket_limit_patch.sql`.

### Booking Slot Is Not Available

Check if the court is already pending, approved, active, under maintenance, inactive, or outside allowed booking hours.

### Customer Does Not See Admin Message

Confirm the admin selected the correct customer and that the customer opens the Notifications page. The app refreshes notifications in real time, but the customer can also use Refresh if the connection was interrupted.

### Payment Proof Cannot Upload

Use JPG, PNG, or PDF only. The file must be 8 MB or smaller.

### First User Is Not Admin

Promote a user in Supabase SQL Editor:

```sql
update public.profiles
set role = 'admin'
where username = 'your_admin_username';
```

## 11. Recommended Client Handover Checklist

- Confirm Supabase URL and anon key are configured.
- Register one admin account.
- Register one test customer account.
- Create and approve a test booking.
- Upload payment proof.
- Upload a customer profile photo.
- Send an admin message to the customer.
- Confirm realtime notification display.
- Confirm web app installation from browser.
- Confirm reports and active timers work.
"""


def esc(value: str) -> str:
    return html.escape(value, quote=True)


def xml_run(value: str, bold: bool = False):
    props = "<w:rPr><w:b/></w:rPr>" if bold else ""
    preserve = ' xml:space="preserve"' if value.startswith(" ") or value.endswith(" ") else ""
    return f"<w:r>{props}<w:t{preserve}>{esc(value)}</w:t></w:r>"


def xml_para(content: str = "", style: str | None = None, indent: str | None = None):
    ppr = []
    if style:
        ppr.append(f'<w:pStyle w:val="{style}"/>')
    if indent:
        ppr.append(f'<w:ind w:left="{indent}"/>')
    ppr_xml = f"<w:pPr>{''.join(ppr)}</w:pPr>" if ppr else ""
    return f"<w:p>{ppr_xml}{content}</w:p>"


def xml_text_para(value: str, style: str | None = None, indent: str | None = None):
    return xml_para(xml_run(value), style=style, indent=indent)


def image_para(rid: str, width_px: int, height_px: int, name: str):
    width_emu = 6_500_000
    height_emu = int(width_emu * height_px / width_px)
    return f"""
<w:p>
  <w:pPr><w:jc w:val="center"/></w:pPr>
  <w:r>
    <w:drawing>
      <wp:inline xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" distT="0" distB="0" distL="0" distR="0">
        <wp:extent cx="{width_emu}" cy="{height_emu}"/>
        <wp:docPr id="{rid[3:]}" name="{esc(name)}"/>
        <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:nvPicPr><pic:cNvPr id="0" name="{esc(name)}"/><pic:cNvPicPr/></pic:nvPicPr>
              <pic:blipFill><a:blip xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:embed="{rid}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>
              <pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{width_emu}" cy="{height_emu}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>
            </pic:pic>
          </a:graphicData>
        </a:graphic>
      </wp:inline>
    </w:drawing>
  </w:r>
</w:p>
"""


def build_docx():
    lines = GUIDE.splitlines()
    body: list[str] = []
    image_rels: list[tuple[str, Path]] = []
    in_code = False
    code_lines: list[str] = []
    image_counter = 1

    for raw in lines:
        if raw.startswith("```"):
            if not in_code:
                in_code = True
                code_lines = []
            else:
                in_code = False
                for code in code_lines:
                    body.append(xml_text_para(code, style="Code"))
                body.append(xml_para())
            continue
        if in_code:
            code_lines.append(raw)
            continue
        if not raw.strip():
            body.append(xml_para())
            continue
        image_match = re.match(r"^!\[(.*?)\]\((.*?)\)$", raw)
        if image_match:
            image_path = DOCS / image_match.group(2)
            rid = f"rId{image_counter + 1}"
            image_counter += 1
            with Image.open(image_path) as img:
                body.append(image_para(rid, img.width, img.height, image_match.group(1)))
            image_rels.append((rid, image_path))
            continue
        if raw.startswith("# "):
            body.append(xml_text_para(raw[2:].strip(), style="Title"))
            continue
        if raw.startswith("## "):
            body.append(xml_text_para(raw[3:].strip(), style="Heading1"))
            continue
        if raw.startswith("### "):
            body.append(xml_text_para(raw[4:].strip(), style="Heading2"))
            continue
        if raw.startswith("- "):
            body.append(xml_text_para("- " + raw[2:].strip(), style="ListBullet", indent="720"))
            continue
        number_match = re.match(r"^(\d+)\.\s+(.*)$", raw)
        if number_match:
            body.append(xml_text_para(f"{number_match.group(1)}. {number_match.group(2)}", style="ListNumber", indent="720"))
            continue
        body.append(xml_text_para(raw.strip()))

    sect = '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1080" w:right="900" w:bottom="1080" w:left="900" w:header="720" w:footer="720" w:gutter="0"/></w:sectPr>'
    document_xml = f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>{"".join(body)}{sect}</w:body></w:document>'
    styles_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/><w:rPr><w:rFonts w:ascii="Aptos" w:hAnsi="Aptos"/><w:sz w:val="22"/></w:rPr><w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:rPr><w:b/><w:sz w:val="38"/><w:color w:val="168A4A"/></w:rPr><w:pPr><w:spacing w:after="240"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:rPr><w:b/><w:sz w:val="30"/><w:color w:val="063B25"/></w:rPr><w:pPr><w:spacing w:before="240" w:after="120"/><w:outlineLvl w:val="0"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:rPr><w:b/><w:sz w:val="25"/><w:color w:val="168A4A"/></w:rPr><w:pPr><w:spacing w:before="180" w:after="100"/><w:outlineLvl w:val="1"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="ListBullet"><w:name w:val="List Bullet"/><w:basedOn w:val="Normal"/></w:style>
  <w:style w:type="paragraph" w:styleId="ListNumber"><w:name w:val="List Number"/><w:basedOn w:val="Normal"/></w:style>
  <w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/><w:basedOn w:val="Normal"/><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="19"/></w:rPr><w:pPr><w:spacing w:after="40"/><w:shd w:val="clear" w:fill="F2FAF5"/></w:pPr></w:style>
</w:styles>'''
    content_types = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>']
    rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>'
    doc_rels_parts = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>']
    for rid, image_path in image_rels:
        doc_rels_parts.append(f'<Relationship Id="{rid}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/{image_path.name}"/>')
    doc_rels_parts.append("</Relationships>")
    doc_rels = "".join(doc_rels_parts)
    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    core = f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>Aps Pickle Zone User Guide</dc:title><dc:creator>Aps Pickle Zone</dc:creator><cp:lastModifiedBy>Aps Pickle Zone</cp:lastModifiedBy><dcterms:created xsi:type="dcterms:W3CDTF">{now}</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">{now}</dcterms:modified></cp:coreProperties>'
    app = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>Codex</Application><DocSecurity>0</DocSecurity><ScaleCrop>false</ScaleCrop><Company>Aps Pickle Zone</Company></Properties>'
    with ZipFile(DOCX_PATH, "w", ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types[0])
        z.writestr("_rels/.rels", rels)
        z.writestr("word/document.xml", document_xml)
        z.writestr("word/styles.xml", styles_xml)
        z.writestr("word/_rels/document.xml.rels", doc_rels)
        z.writestr("docProps/core.xml", core)
        z.writestr("docProps/app.xml", app)
        for _, image_path in image_rels:
            z.write(image_path, f"word/media/{image_path.name}")


def main():
    DOCS.mkdir(parents=True, exist_ok=True)
    build_images()
    MD_PATH.write_text(GUIDE, encoding="utf-8")
    build_docx()
    with ZipFile(DOCX_PATH, "r") as z:
        bad = z.testzip()
    print(f"Generated {MD_PATH}")
    print(f"Generated {DOCX_PATH}")
    print(f"DOCX package check: {bad or 'ok'}")


if __name__ == "__main__":
    main()

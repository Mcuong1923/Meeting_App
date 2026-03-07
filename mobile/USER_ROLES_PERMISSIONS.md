# PhÃ¢n Quyá»n Há» Thá»ng - User Roles & Permissions

## Tá»ng Quan CÃ¡c Role

Há» thá»ng cÃ³ **5 roles** chÃ­nh:
1. **Admin** - Quáº£n trá» viÃªn
2. **Director** - GiÃ¡m Äá»c
3. **Manager** - Quáº£n lÃ½
4. **Employee** - NhÃ¢n viÃªn
5. **Guest** - KhÃ¡ch

---

## 1. ADMIN (Quáº£n trá» viÃªn)

### MÃ´ táº£
- **Quyá»n cao nháº¥t** trong há» thá»ng
- ToÃ n quyá»n quáº£n lÃ½ há» thá»ng

### Permissions
```dart
[
  'manage_all_users',        // Quáº£n lÃ½ táº¥t cáº£ users
  'manage_all_meetings',     // Quáº£n lÃ½ táº¥t cáº£ meetings
  'manage_system_settings',  // Quáº£n lÃ½ cÃ i Äáº·t há» thá»ng
  'view_all_reports',        // Xem táº¥t cáº£ bÃ¡o cÃ¡o
  'manage_departments',      // Quáº£n lÃ½ phÃ²ng ban
  'manage_rooms',            // Quáº£n lÃ½ phÃ²ng há»p
]
```

### Quyá»n Táº¡o Meeting
- â **canCreateMeeting**: `true`
- â **needsApproval**: `false` (Auto-approve)
- â **allowedMeetingTypes**: Táº¥t cáº£ loáº¡i (`personal`, `team`, `department`, `company`)

### Quyá»n Trong Firestore Rules

#### Users Collection
- â **Read**: Báº¥t ká»³ user nÃ o (owner, admin, director)
- â **Create**: Owner tá»± táº¡o
- â **Update**: Admin/Director HOáº¶C owner (nhÆ°ng khÃ´ng ÄÆ°á»£c sá»­a role/isRoleApproved/departmentId)
- â **Delete**: Admin HOáº¶C Director (trong cÃ¹ng department)

#### Meetings Collection
- â **Read**: Táº¥t cáº£ cÃ¡c cuá»c há»p trÃªn há» thá»ng
- â **Create**: CÃ³ thá» táº¡o meeting
- â **Update**: CÃ³ quyá»n duyá»t, tá»« chá»i hoáº·c cancel táº¥t cáº£ cuá»c há»p
- â **Delete**: CÃ³ quyá»n xoÃ¡ cá»©ng (hard delete) - LÆ°u Ã½: Chá» Admin má»i cÃ³ quyá»n hard delete

#### Rooms Collection
- â **Read**: Táº¥t cáº£ authenticated users
- â **Create**: Chá» Admin
- â **Update**: Chá» Admin
- â **Delete**: Chá» Admin

#### Departments Collection
- â **Read**: Táº¥t cáº£ authenticated users
- â **Write**: Admin/Director

#### Room Bookings Collection
- â **Read**: Táº¥t cáº£ cÃ¡c Äáº·t phÃ²ng trÃªn há» thá»ng
- â **Create**: CÃ³ thá» tá»± do Äáº·t phÃ²ng
- â **Update**: CÃ³ quyá»n duyá»t, tá»« chá»i hoáº·c cancel táº¥t cáº£ Äáº·t phÃ²ng
- â **Delete**: CÃ³ quyá»n xoÃ¡ cá»©ng (hard delete)

#### Notifications Collection
- â **Read**: Owner (createdBy), Recipients, HOáº¶C Admin
- â **Create**: Admin, Director (cÃ¹ng department), Manager (cÃ¹ng team)
- â **Update**: Owner (createdBy) HOáº¶C Admin
- â **Delete**: Owner (createdBy) HOáº¶C Admin

#### Reports Collection
- â **Read**: Táº¥t cáº£ authenticated users
- â **Create/Update**: Chá» Admin
- â **Delete**: Chá» Admin

#### Maintenance Records Collection
- â **Read**: Táº¥t cáº£ authenticated users
- â **Create/Update**: Chá» Admin
- â **Delete**: Chá» Admin

#### Decisions Collection
- â **Read**: Táº¥t cáº£ authenticated users
- â **Create**: Táº¥t cáº£ authenticated users
- â **Update**: Owner HOáº¶C Admin/Director/Manager
- â **Delete**: Owner HOáº¶C Admin/Director

#### Tasks Collection
- â **Read**: Táº¥t cáº£ authenticated users
- â **Create**: Táº¥t cáº£ authenticated users
- â **Update**: Owner HOáº¶C Assignee HOáº¶C Admin/Director/Manager
- â **Delete**: Owner HOáº¶C Admin/Director/Manager

#### Files Collection
- â **Read**: Táº¥t cáº£ authenticated users
- â **Create**: Táº¥t cáº£ authenticated users
- â **Update**: Uploader HOáº¶C Admin/Director/Manager
- â **Delete**: Uploader HOáº¶C Admin/Director

---

## 2. DIRECTOR (GiÃ¡m Äá»c)

### MÃ´ táº£
- Quáº£n lÃ½ cáº¥p trung
- Quáº£n lÃ½ phÃ²ng ban

### Permissions
```dart
[
  'manage_department_users',      // Quáº£n lÃ½ users trong phÃ²ng ban
  'manage_department_meetings',   // Quáº£n lÃ½ meetings trong phÃ²ng ban
  'view_department_reports',      // Xem bÃ¡o cÃ¡o phÃ²ng ban
  'manage_rooms',                 // Quáº£n lÃ½ phÃ²ng há»p
]
```

### Quyá»n Táº¡o Meeting
- â **canCreateMeeting**: `true`
- â **needsApproval**: `false` (Auto-approve)
- â **allowedMeetingTypes**: `team`, `department`, `company`

### Quyá»n Trong Firestore Rules

#### Users Collection
- â **Read**: Báº¥t ká»³ user nÃ o (owner, admin, director)
- â **Update**: Director cÃ³ thá» update users trong cÃ¹ng department
- â **Delete**: Director cÃ³ thá» delete users trong cÃ¹ng department

#### Meetings Collection
- â **Read**: CÃ¡c cuá»c há»p trong cÃ¹ng phÃ²ng ban HOáº¶C cÃ¡c cuá»c há»p cÃ³ máº·t trong danh sÃ¡ch tham gia HOáº¶C do mÃ¬nh táº¡o
- â **Create**: CÃ³ thá» táº¡o meeting
- â **Update**: CÃ³ quyá»n duyá»t, tá»« chá»i hoáº·c cancel cuá»c há»p trong scope phÃ²ng ban (approvalLevel = department) HOáº¶C do mÃ¬nh táº¡o
- â **Delete**: KhÃ´ng ÄÆ°á»£c phÃ©p (Chá» cÃ³ thá» cancel meeting, thay Äá»i tráº¡ng thÃ¡i thÃ nh cancelled)

#### Departments Collection
- â **Write**: Director cÃ³ thá» quáº£n lÃ½ departments

#### Room Bookings Collection
- â **Read**: CÃ¡c Äáº·t phÃ²ng trong máº¡ng lÆ°á»i tham gia hoáº·c phÃ²ng ban
- â **Create**: CÃ³ thá» táº¡o booking
- â **Update**: Owner HOáº¶C Director (cancel booking trong department scope)
- â **Delete**: KhÃ´ng ÄÆ°á»£c phÃ©p (Chá» cÃ³ thá» update tráº¡ng thÃ¡i)

#### Notifications Collection
- â **Create**: Director cÃ³ thá» táº¡o notifications (trong cÃ¹ng department)
- â **Update/Delete**: KhÃ´ng thá» sá»­a/xÃ³a notifications cá»§a ngÆ°á»i khÃ¡c (chá» ÄÆ°á»£c sá»­a/xÃ³a notification do mÃ¬nh táº¡o)

---

## 3. MANAGER (Quáº£n lÃ½)

### MÃ´ táº£
- Quáº£n lÃ½ team/dá»± Ã¡n
- Quáº£n lÃ½ meetings cá»§a team

### Permissions
```dart
[
  'manage_team_users',        // Quáº£n lÃ½ users trong team
  'manage_team_meetings',     // Quáº£n lÃ½ meetings cá»§a team
  'view_team_reports',        // Xem bÃ¡o cÃ¡o team
  'approve_team_meetings',    // PhÃª duyá»t meetings cá»§a team
]
```

### Quyá»n Táº¡o Meeting
- â **canCreateMeeting**: `true`
- â **needsApproval**: `false` (Auto-approve)
- â **allowedMeetingTypes**: `personal`, `team`

### Quyá»n Trong Firestore Rules

#### Meetings Collection
- â **Read**: CÃ¡c cuá»c há»p trong cÃ¹ng nhÃ³m (team) HOáº¶C cÃ¡c cuá»c há»p cÃ³ máº·t trong danh sÃ¡ch tham gia HOáº¶C do mÃ¬nh táº¡o
- â **Create**: CÃ³ thá» táº¡o meeting
- â **Update**: CÃ³ quyá»n duyá»t, tá»« chá»i hoáº·c cancel cuá»c há»p trong scope team (approvalLevel = team) HOáº¶C do mÃ¬nh táº¡o
- â **Delete**: KhÃ´ng ÄÆ°á»£c phÃ©p (Chá» cÃ³ thá» update tráº¡ng thÃ¡i)

#### Room Bookings Collection
- â **Read**: CÃ¡c Äáº·t phÃ²ng trong máº¡ng lÆ°á»i tham gia hoáº·c team
- â **Create**: CÃ³ thá» táº¡o booking
- â **Update**: Owner HOáº¶C Manager (cancel booking trong team scope)
- â **Delete**: KhÃ´ng ÄÆ°á»£c phÃ©p (Chá» cÃ³ thá» update tráº¡ng thÃ¡i)

#### Notifications Collection
- â **Create**: Manager cÃ³ thá» táº¡o notifications (trong cÃ¹ng team)
- â **Update/Delete**: KhÃ´ng thá» sá»­a/xÃ³a notifications cá»§a ngÆ°á»i khÃ¡c (chá» ÄÆ°á»£c sá»­a/xÃ³a notification do mÃ¬nh táº¡o)

#### Decisions Collection
- â **Update**: Owner HOáº¶C Manager
- â **Delete**: Chá» Owner/Director/Admin

#### Tasks Collection
- â **Update**: Owner HOáº¶C Assignee HOáº¶C Manager
- â **Delete**: Owner HOáº¶C Manager

#### Files Collection
- â **Update**: Uploader HOáº¶C Manager
- â **Delete**: Chá» Uploader/Director/Admin

---

## 4. EMPLOYEE (NhÃ¢n viÃªn)

### MÃ´ táº£
- NhÃ¢n viÃªn thÃ´ng thÆ°á»ng
- Táº¡o cuá»c há»p cÃ¡ nhÃ¢n

### Permissions
```dart
[
  'create_personal_meetings',  // Táº¡o meetings cÃ¡ nhÃ¢n
  'view_personal_reports',     // Xem bÃ¡o cÃ¡o cÃ¡ nhÃ¢n
  'join_invited_meetings',     // Tham gia meetings ÄÆ°á»£c má»i
]
```

### Quyá»n Táº¡o Meeting
- â **canCreateMeeting**: `true`
- â **needsApproval**: `true` (Cáº§n phÃª duyá»t)
- â **allowedMeetingTypes**: Chá» `personal`

### Quyá»n Trong Firestore Rules

#### Meetings Collection
- â **Read**: Chá» Äá»c cÃ¡c cuá»c há»p do mÃ¬nh táº¡o (Owner) HOáº¶C mÃ¬nh náº±m trong danh sÃ¡ch participants
- â **Create**: CÃ³ thá» táº¡o meeting (chá» type=personal, auto set pending, báº¯t buá»c cÃ³ lÃ½ do khi vÆ°á»£t cáº¥p)
- â **Update**: Chá» Owner (thay Äá»i thÃ´ng tin ná»i bá» náº¿u pending hoáº·c Äá»i sang cancelled)
- â **Delete**: KhÃ´ng ÄÆ°á»£c phÃ©p (Chá» update tráº¡ng thÃ¡i thÃ nh cancelled)

#### Room Bookings Collection
- â **Read**: Dá»±a vÃ o danh sÃ¡ch meeting tham gia
- â **Create**: Báº¯t buá»c pháº£i gáº¯n vá»i má»t meeting ÄÃ£ ÄÆ°á»£c duyá»t (approved) mÃ  employee lÃ  ngÆ°á»i táº¡o hoáº·c tham gia
- â **Update**: Chá» Owner (cancel rule)
- â **Delete**: KhÃ´ng ÄÆ°á»£c phÃ©p

#### Decisions Collection
- â **Create**: CÃ³ thá» táº¡o decisions
- â **Update**: Chá» Owner
- â **Delete**: Chá» Owner

#### Tasks Collection
- â **Create**: CÃ³ thá» táº¡o tasks
- â **Update**: Owner HOáº¶C Assignee (náº¿u ÄÆ°á»£c assign)
- â **Delete**: Chá» Owner/Manager/Director/Admin

#### Files Collection
- â **Create**: CÃ³ thá» upload files
- â **Update**: Chá» Uploader
- â **Delete**: Chá» Uploader/Director/Admin

---

## 5. GUEST (KhÃ¡ch)

### MÃ´ táº£
- KhÃ¡ch má»i
- Chá» tham gia meetings ÄÆ°á»£c má»i

### Permissions
```dart
[
  'join_invited_meetings',  // Chá» tham gia meetings ÄÆ°á»£c má»i
]
```

### Quyá»n Táº¡o Meeting
- â **canCreateMeeting**: `false`
- â **needsApproval**: `false`
- â **allowedMeetingTypes**: `[]` (KhÃ´ng cÃ³)

### Quyá»n Trong Firestore Rules

#### Meetings Collection
- â **Create**: KhÃ´ng thá» táº¡o meeting
- â **Read**: CHá» cÃ³ thá» xem cÃ¡c cuá»c há»p mÃ  Guest náº±m trong danh sÃ¡ch tham gia (participant)
- â **Update/Delete**: KhÃ´ng thá» sá»­a hoáº·c xÃ³a

#### Room Bookings Collection
- â **Read**: Dá»±a vÃ o thÃ´ng tin meeting
- â **Create**: KhÃ´ng ÄÆ°á»£c táº¡o booking Äá»c láº­p. CHá» ÄÆ°á»£c phÃ©p táº¡o booking náº¿u cÃ³ meetingId, thÆ° má»i pháº£i trÃºng user ÄÃ³ lÃ  participant, vÃ  meeting pháº£i "approved".
- â **Update/Delete**: KhÃ´ng thá» sá»­a hoáº·c xÃ³a

#### Decisions Collection
- â **Create**: CÃ³ thá» táº¡o decisions
- â **Update**: Chá» Owner
- â **Delete**: Chá» Owner

#### Tasks Collection
- â **Create**: CÃ³ thá» táº¡o tasks
- â **Update**: Owner HOáº¶C Assignee
- â **Delete**: Chá» Owner/Manager/Director/Admin

#### Files Collection
- â **Create**: CÃ³ thá» upload files
- â **Update**: Chá» Uploader
- â **Delete**: Chá» Uploader/Director/Admin

---

## Báº£ng Tá»ng Há»£p Quyá»n Táº¡o Meeting

| Role | Can Create | Needs Approval | Auto-Approve | Allowed Types |
|------|------------|----------------|--------------|---------------|
| **Admin** | â Yes | â No | â Yes | All (personal, team, department, company) |
| **Director** | â Yes | â No | â Yes | team, department, company |
| **Manager** | â Yes | â No | â Yes | personal, team |
| **Employee** | â Yes | â Yes | â No | personal only |
| **Guest** | â No | â No | â No | None |

---

## Báº£ng Tá»ng Há»£p Quyá»n PhÃª Duyá»t Meeting

| Role | Can Approve | Can Reject | Can Cancel |
|------|-------------|------------|------------|
| **Admin** | â Yes | â Yes | â Yes |
| **Director** | â Yes | â Yes | â Yes |
| **Manager** | â Yes | â Yes | â No (chá» cancel own) |
| **Employee** | â No | â No | â Yes (chá» own) |
| **Guest** | â No | â No | â No |

---

## Quyá»n Quáº£n LÃ½ PhÃ²ng Há»p (Rooms)

| Role | Create Room | Update Room | Delete Room | View Rooms |
|------|-------------|-------------|-------------|------------|
| **Admin** | â Yes | â Yes | â Yes | â Yes |
| **Director** | â No | â No | â No | â Yes |
| **Manager** | â No | â No | â No | â Yes |
| **Employee** | â No | â No | â No | â Yes (chá» khi cÃ³ meeting reference) |
| **Guest** | â No | â No | â No | â Yes (chá» khi join meeting) |

---

## Quyá»n Quáº£n LÃ½ Users

| Role | Create User | Update User | Delete User | View Users |
|------|-------------|-------------|-------------|------------|
| **Admin** | â Yes | â Yes | â Yes | â Yes |
| **Director** | â No | â Yes (same dept) | â Yes (same dept) | â Yes |
| **Manager** | â No | â No | â No | â Yes |
| **Employee** | â No | â Yes (own only) | â No | â Yes |
| **Guest** | â No | â Yes (own only) | â No | â Yes |

---

## Quyá»n Quáº£n LÃ½ Departments

| Role | Create Dept | Update Dept | Delete Dept | View Depts |
|------|-------------|-------------|-------------|------------|
| **Admin** | â Yes | â Yes | â Yes | â Yes |
| **Director** | â Yes | â Yes | â No | â Yes |
| **Manager** | â No | â No | â No | â Yes |
| **Employee** | â No | â No | â No | â Yes |
| **Guest** | â No | â No | â No | â Yes |

---

## Quyá»n Quáº£n LÃ½ Room Bookings

| Role | Create Booking | Update Booking | Delete Booking | Approve Booking |
|------|----------------|----------------|----------------|-----------------|
| **Admin** | â Yes | â Yes | â Yes | â Yes |
| **Director** | â Yes | â Yes (own/cancel) | â No | â Yes |
| **Manager** | â Yes | â Yes (own/cancel) | â No | â Yes |
| **Employee** | â Yes (gáº¯n meeting ÄÃ£ duyá»t) | â Yes (own/cancel scope) | â No | â No |
| **Guest** | â Yes (gáº¯n meeting ÄÃ£ duyá»t) | â Yes (own/cancel scope) | â No | â No |

---

## Quyá»n Quáº£n LÃ½ Notifications

| Role | Create Notification | Update Notification | Delete Notification | Read Notification |
|------|---------------------|---------------------|---------------------|-------------------|
| **Admin** | â Yes | â Yes | â Yes | â Yes |
| **Director** | â Yes (same dept) | â Yes (own only) | â Yes (own only) | â Yes (own/recipient) |
| **Manager** | â Yes (same team) | â Yes (own only) | â Yes (own only) | â Yes (own/recipient) |
| **Employee** | â No | â Yes (own only) | â Yes (own only) | â Yes (own/recipient) |
| **Guest** | â No | â Yes (own only) | â Yes (own only) | â Yes (own/recipient) |

---

## Quyá»n Quáº£n LÃ½ Reports

| Role | Create Report | Update Report | Delete Report | View Reports |
|------|---------------|---------------|---------------|--------------|
| **Admin** | â Yes | â Yes | â Yes | â Yes (all) |
| **Director** | â No | â No | â No | â Yes (department) |
| **Manager** | â No | â No | â No | â Yes (team) |
| **Employee** | â No | â No | â No | â Yes (personal) |
| **Guest** | â No | â No | â No | â No |

---

## Quyá»n Quáº£n LÃ½ Maintenance Records

| Role | Create Record | Update Record | Delete Record | View Records |
|------|---------------|---------------|---------------|--------------|
| **Admin** | â Yes | â Yes | â Yes | â Yes |
| **Director** | â No | â No | â No | â Yes |
| **Manager** | â No | â No | â No | â Yes |
| **Employee** | â No | â No | â No | â Yes |
| **Guest** | â No | â No | â No | â Yes |

---

## Quyá»n Quáº£n LÃ½ Decisions

| Role | Create Decision | Update Decision | Delete Decision |
|------|----------------|-----------------|-----------------|
| **Admin** | â Yes | â Yes | â Yes |
| **Director** | â Yes | â Yes | â Yes |
| **Manager** | â Yes | â Yes | â Yes |
| **Employee** | â Yes | â Yes (own only) | â Yes (own only) |
| **Guest** | â Yes | â Yes (own only) | â Yes (own only) |

---

## Quyá»n Quáº£n LÃ½ Tasks

| Role | Create Task | Update Task | Delete Task | Assign Task |
|------|-------------|-------------|-------------|-------------|
| **Admin** | â Yes | â Yes | â Yes | â Yes |
| **Director** | â Yes | â Yes | â Yes | â Yes |
| **Manager** | â Yes | â Yes | â Yes | â Yes |
| **Employee** | â Yes | â Yes (own/assigned) | â No | â Yes |
| **Guest** | â Yes | â Yes (own/assigned) | â No | â Yes |

---

## Quyá»n Quáº£n LÃ½ Files

| Role | Upload File | Update File | Delete File |
|------|-------------|-------------|-------------|
| **Admin** | â Yes | â Yes | â Yes |
| **Director** | â Yes | â Yes | â Yes |
| **Manager** | â Yes | â Yes | â No |
| **Employee** | â Yes | â Yes (own only) | â No |
| **Guest** | â Yes | â Yes (own only) | â No |

---

## Quyá»n Comments (Meeting Comments)

| Role | Create Comment | Update Comment | Delete Comment |
|------|----------------|----------------|----------------|
| **Admin** | â Yes (if participant) | â Yes (own only) | â Yes (own only) |
| **Director** | â Yes (if participant) | â Yes (own only) | â Yes (own only) |
| **Manager** | â Yes (if participant) | â Yes (own only) | â Yes (own only) |
| **Employee** | â Yes (if participant) | â Yes (own only) | â Yes (own only) |
| **Guest** | â Yes (if participant) | â Yes (own only) | â Yes (own only) |

**LÆ°u Ã½**: Chá» participants cá»§a meeting má»i cÃ³ thá» comment.

---

## TÃ³m Táº¯t Quyá»n Theo Collection

### Collections Chá» Admin Má»i CÃ³ Quyá»n Write:
- **rooms** (Create/Update/Delete)
- **reports** (Create/Update/Delete)
- **maintenance_records** (Create/Update/Delete)

### Collections Admin/Director CÃ³ Quyá»n Write:
- **departments** (Create/Update)
- **users** (Update/Delete - vá»i Äiá»u kiá»n)

### Collections Admin/Director/Manager CÃ³ Quyá»n Write:
- **meetings** (Update - Cancel Scope)
- **room_bookings** (Update - Cancel Scope)
- **decisions** (Update/Delete)
- **tasks** (Update/Delete)
- **files** (Update)

### Collections Táº¥t Cáº£ Users CÃ³ Quyá»n Write:
- **meetings** (Create - nhÆ°ng Employee cáº§n approval)
- **room_bookings** (Create)
- **decisions** (Create)
- **tasks** (Create)
- **files** (Create/Upload)
- **comments** (Create - náº¿u lÃ  participant)

*(Quyá»n Create Notifications chá» giá»i háº¡n cho System, Admin, Director, Manager. Employee khÃ´ng ÄÆ°á»£c tá»± do push notifications ngoáº¡i trá»« trigger cá»§a function/backend).*

---

## LÆ°u Ã Quan Trá»ng

1. **Auto-Approve**: Admin, Director, Manager táº¡o meeting sáº½ ÄÆ°á»£c **auto-approve** ngay láº­p tá»©c (khÃ´ng cáº§n phÃª duyá»t).

2. **Employee Approval**: Employee táº¡o meeting sáº½ á» tráº¡ng thÃ¡i **pending** vÃ  cáº§n ÄÆ°á»£c Admin/Director/Manager phÃª duyá»t.

3. **Guest Limitations**: Guest khÃ´ng thá» táº¡o meeting, chá» cÃ³ thá» tham gia meetings ÄÆ°á»£c má»i.

4. **Department Scope**: Director chá» cÃ³ thá» quáº£n lÃ½ users/meetings trong cÃ¹ng department.

5. **Team Scope**: Manager chá» cÃ³ thá» quáº£n lÃ½ users/meetings trong team cá»§a mÃ¬nh.

6. **Owner Rights**: Táº¥t cáº£ users Äá»u cÃ³ quyá»n update/delete cÃ¡c records mÃ  há» táº¡o (owner rights tuá»³ thuá»c tá»«ng collection).

7. **Delete Restrictions**: HÃ nh Äá»ng xÃ³a meetings vÃ  bookings hiá»n bá» khoÃ¡ cá»©ng (Hard delete), chá» cÃ³ **Admin** má»i ÄÆ°á»£c thá»±c hiá»n hÃ nh Äá»ng nÃ y báº±ng Firestore Rule. Má»i users khÃ¡c (ká» cáº£ owner) chá» cÃ³ thá» `update` thuá»c tÃ­nh `status = "cancelled"`. Má»i booking láº» (cá»§a Employee/Guest) Äá»u yÃªu cáº§u gáº¯n cháº·t vÃ o Meeting báº±ng ID.

---

---

## 6. ACCOUNT TYPES & STATUSES

### Domain Policy
- **Internal domain**: `company.com` only
- All other emails (gmail.com, partner.com, ...) are **external**
- `isInternalEmail(email)` = `email.endsWith('@company.com')`

### Migration Rule (Golden Rule)
> **NEVER overwrite role** if `role != null && role != 'guest'`
> Gmail admin/director/manager/employee keep their role during migration.

### Internal Users (@company.com):
| Step | Values |
|------|--------|
| New signup | `accountType=internal`, `role=employee`, `status=pending` |
| Request dept | `requestedDepartmentId`, `requestedTeamId`, status stays `pending` |
| Admin approve | `status=active`, `isRoleApproved=true`, assign role/dept/team |

### External Users (gmail, partner, ...):
| Step | Values |
|------|--------|
| New signup | `accountType=external`, `role=guest`, `status=active` |
| Use app immediately | Limited permissions (guest scope) |
| Admin can promote later | Can upgrade role anytime |

### Lazy Migration (on existing user login):
| Condition | Action |
|-----------|--------|
| `accountType` missing + internal + role=guest/null | internal/employee/pending |
| `accountType` missing + internal + role=admin/... | internal, keep role, status=active |
| `accountType` missing + external + role=admin/... | external, keep role, status=active |
| `accountType` missing + external + role=null | external/guest/active |
| `status` missing | active (never lock out existing users) |
| Has `pendingRole`/`pendingDepartment` | Copy to `requestedRole`/`requestedDepartmentId`, delete old fields |

### Acceptance Test Cases:
1. `nvancuong792@gmail.com` (role=admin) login -> role=admin, accountType=external, status=active
2. Gmail manager/director login -> keep role, status=active
3. Gmail guest login -> role=guest, accountType=external, status=active
4. `user@company.com` (role=guest, old schema) login -> internal/employee/pending
5. Signup `new@company.com` -> internal/employee/pending
6. Signup `new@gmail.com` -> external/guest/active

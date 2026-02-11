\# Antigravity 🚀

\### Enterprise IT Operations \& Asset Intelligence System



\*\*Antigravity\*\* is a unified platform for IT Professionals and Service Providers. It goes beyond simple inventory tracking to manage the entire IT ecosystem: Hardware, Cloud Licenses, Network Configurations, Field Operations, and HR Integration across \*\*multiple companies/tenants\*\*.



---



\## 🛠 Tech Stack



\- \*\*Mobile App:\*\* Flutter (Android / iOS)

\- \*\*Offline Engine:\*\* `hive` or `sqlite` (Local-first architecture)

\- \*\*Backend:\*\* Supabase (PostgreSQL, Auth, Storage, Realtime)

\- \*\*ERP Integration:\*\* Odoo (XML-RPC/JSON-RPC)

\- \*\*Security:\*\* AES Encryption for stored credentials

\- \*\*Maps:\*\* `Maps\_flutter` or `flutter\_map` (Geotagging)



---



\## 🏢 Architecture: Multi-Company \& Site-Centric



The system is designed for scalability:

\- \*\*Multi-Tenant:\*\* Manage assets for different clients (Companies) completely isolated.

\- \*\*Location-Based Hierarchy:\*\*

&nbsp; - Company -> Branch (e.g., October Branch) -> Room (e.g., Server Room) -> Rack/Cabinet.

&nbsp; - Assets can be assigned to a \*\*Person\*\* OR a \*\*Location\*\*.



---



\## 📱 Module 1: Advanced Asset Intelligence 🧠



\### 1. Hardware \& Network Assets 💻

\- \*\*Deep Specs:\*\* Track CPU, RAM, Storage, Hostname.

\- \*\*Network DNA:\*\*

&nbsp; - \*\*Static IP \& MAC:\*\* Essential for firewalls and DHCP reservations.

&nbsp; - \*\*Configuration Backup:\*\* Upload device config files (e.g., `.conf`, `.backup` for Switches/Firewalls) to Supabase Storage.

&nbsp; - \*\*Asset Wiki:\*\* Notes field for VLAN IDs, Gateway info, or specific troubleshooting steps per device.

\- \*\*Secure Vault:\*\*

&nbsp; - \*\*Encrypted Credentials:\*\* Store Admin Passwords/SSH Keys for devices (e.g., DVR Password) securely within the asset record.



\### 2. Cloud \& Identity Assets (SaaS) ☁️

\*Managing the "Invisible" Inventory.\*

\- \*\*Identity Linking:\*\* Map Active Directory/LDAP accounts to employees.

\- \*\*License Management:\*\* Track Microsoft 365 (E3, Business Std), Adobe, etc.

\- \*\*Offboarding Intelligence:\*\*

&nbsp; - When an employee resigns, the system alerts: "Retrieve Laptop + \*\*Disable AD Account\*\* + \*\*Revoke Office 365 License\*\*".



---



\## 📱 Module 2: Field Operations (The Toolkit) 🧰



\### 3. Fast Audit Mode (Stock Count) 🕵️‍♂️

\*For rapid inventory checks.\*

\- \*\*Continuous Scan:\*\* Open camera and scan barcodes non-stop.

\- \*\*Instant Report:\*\*

&nbsp; - ✅ \*\*Matched:\*\* Item is where it should be.

&nbsp; - ⚠️ \*\*Misplaced:\*\* Item belongs to "HQ" but found in "Branch X".

&nbsp; - ❌ \*\*Missing:\*\* Item listed in this room but not scanned.



\### 4. Offline Mode (No Internet? No Problem) 📶

\- \*\*Local-First:\*\* All data (Assets, Locations) is cached locally on the phone.

\- \*\*Sync Queue:\*\* Perform audits, move assets, or install devices offline. The app auto-syncs when connectivity returns.



\### 5. Geotagging \& Last Known Location 📍

\- \*\*Auto-Tag:\*\* Every scan (Audit or Handover) records the GPS coordinates.

\- \*\*Map View:\*\* Visualize where your assets are physically distributed.



---



\## 📱 Module 3: Workflow \& Approvals 📋



\### 6. Deployment \& Installation

\- \*\*Proof of Installation:\*\* Take a photo of the installed device (e.g., CCTV mounted, Cabling done) and attach it to the asset record.

\- \*\*Site Transfer:\*\* Request to move assets from "Main Store" to "Site A".

\- \*\*Approval Chain:\*\*

&nbsp; - Junior IT requests transfer -> IT Manager receives Notification -> Manager Approves -> Assets moved in system.



\### 7. Employee Self-Service Portal 🙋‍♂️

\- \*\*My Custody:\*\* Employees can see what devices are assigned to them.

\- \*\*Report Issue:\*\* "My laptop screen is flickering" -> Creates a ticket for IT.

\- \*\*Request Asset:\*\* Request a new Mouse/Headset -> Manager Approval -> IT Fulfillment.



---



\## 📱 Module 4: HR \& Paperless Operations 🤝



\### 8. Digital Custody \& Signatures

\- \*\*On-Screen Signing:\*\* Employee signs for assets directly on the tablet.

\- \*\*PDF Generation:\*\* Auto-creates "Asset Handover Form" with:

&nbsp; - Company Logo.

&nbsp; - Asset Serials \& Accessories.

&nbsp; - Employee Signature \& Timestamp.

\- \*\*Cloud Archiving:\*\* Signed PDF is saved to the asset history forever.



\### 9. Employee Lifecycle (Onboarding/Offboarding)

\- \*\*Synced with HR:\*\* New hires appear automatically from Odoo/HR system.

\- \*\*Clearance Process:\*\*

&nbsp; - \*\*Dashboard:\*\* "Pending Clearances".

&nbsp; - \*\*Checklist:\*\* Ensure all hardware is returned and all cloud accounts are disabled before signing off.



---



\## 🗄 Database Schema (Enhanced)



\### `locations`

| Field | Type | Description |

| :--- | :--- | :--- |

| `id` | UUID | Primary Key |

| `company\_id` | FK | Tenant |

| `name` | String | "Server Room - October" |

| `type` | Enum | `Branch`, `Room`, `Warehouse` |



\### `assets`

| Field | Type | Description |

| :--- | :--- | :--- |

| `id` | UUID | Primary Key |

| `config\_file\_url` | String | Link to backup file |

| `secure\_credentials`| Encrypted String | Admin/Root password |

| `last\_seen\_lat` | Float | GPS Latitude |

| `last\_seen\_long` | Float | GPS Longitude |

| `cloud\_license\_id` | FK | Link to M365/SaaS table |



\### `audit\_sessions`

| Field | Type | Description |

| :--- | :--- | :--- |

| `id` | UUID | Primary Key |

| `location\_id` | FK | Where the audit happened |

| `performed\_by` | FK | IT Admin |

| `scanned\_items` | JSON | List of verified IDs |

| `missing\_items` | JSON | List of missing IDs |

| `report\_pdf` | String | URL to final audit report |



\### `requests\_approvals`

| Field | Type | Description |

| :--- | :--- | :--- |

| `id` | UUID | Primary Key |

| `requester\_id` | FK | Employee/IT User |

| `approver\_id` | FK | Manager |

| `type` | Enum | `Asset\_Transfer`, `New\_Device` |

| `status` | Enum | `Pending`, `Approved`, `Rejected` |



---



\## 🚀 Roadmap



\- \[ ] \*\*Phase 1: Core \& Offline:\*\* Setup Supabase, Local Database (Hive), and Basic Asset CRUD.

\- \[ ] \*\*Phase 2: Network \& Intelligence:\*\* Implement Config backups, Secure Vault, and Geotagging.

\- \[ ] \*\*Phase 3: Operations:\*\* Build Fast Audit Mode and PDF Generation.

\- \[ ] \*\*Phase 4: Workflows:\*\* Implement Approval systems and Site Transfers.

\- \[ ] \*\*Phase 5: The Human Element:\*\* Employee Portal and HR/Odoo Integration.


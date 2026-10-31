# Member D - rooms and beds tables

## Rooms table
The `rooms` table stores information about hospital rooms.

- `room_id` is the unique ID for each room.
- `department_id` links a room to a department. It can be empty if the room is not assigned to a department.
- `room_no` stores the room number and must be unique.
- `room_type` stores whether the room is a Ward, Private, or ICU room.
- `daily_rate` stores the room's daily cost and must be greater than zero.

## Beds table
The `beds` table stores the beds in each room.

- `bed_id` is the unique ID for each bed.
- `room_id` links the bed to a room.
- `bed_no` stores the bed number within that room.
- `status` shows whether the bed is Available, Occupied, or under Maintenance. New beds are Available by default.

Each bed must belong to an existing room. The same bed number can be used in different rooms, but not twice in one room.

## Table relationships
A department can have multiple rooms. A room can contain multiple beds. The foreign keys connect rooms to departments and beds to rooms.

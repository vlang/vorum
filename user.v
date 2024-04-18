module main

@[table: 'users']
struct User {
mut:
	id        int
	name      string
	is_banned bool
	is_admin  bool
}

fn (mut app App) get_user(user_id int) ?User {
	users := sql app.db {
		select from User where id == user_id
	} or {
		app.warn(err.str())
		[]User{}
	}

	if users.len == 0 {
		return none
	}

	return users.first()
}

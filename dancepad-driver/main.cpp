#include <allegro5/allegro.h>
#include <allegro5/allegro_primitives.h>
#include <cstdio>
#include <cstdint>
#include <stdexcept>



#include <conio.h>
#define STRICT
#define WIN32_LEAN_AND_MEAN
#include <windows.h>


bool joystick_button_state[INT16_MAX] = { false };
bool key_state[ALLEGRO_KEY_MAX] = { false };

// Map to HID gamepad buttons.
enum {
DANCEPAD_KEY_UP = 2,
DANCEPAD_KEY_DOWN = 1,
DANCEPAD_KEY_RIGHT = 3,
DANCEPAD_KEY_LEFT = 0,
DANCEPAD_KEY_SELECT = 8,
DANCEPAD_KEY_START = 9
};

// One-hot encoding for event packets to be sent.
enum {
	EVENTCODE_UP = 1,
	EVENTCODE_DOWN = 2,
	EVENTCODE_LEFT = 4,
	EVENTCODE_RIGHT = 8,
	EVENTCODE_SELECT = 16,
	EVENTCODE_START = 32,
	EVENTCODE_IDLE = 0
};

inline std::wstring convert(const std::string& as)
{
	wchar_t* buf = new wchar_t[as.size() * 2 + 2];
	swprintf(buf, as.size() * 2 + 2, L"%S", as.c_str());
	std::wstring rval = buf;
	delete[] buf;
	return rval;
}

/*
Instructions: 
1. Find the COM port that is connected to the board (use Device Manager, right-click on Windows icon)
2. Plug in the Dancepad.
3. Type in the COM port's name (ie. COM4)
4. If all goes well, the Allegro display should pop up. Highlight the Allegro display and use keyboard inputs for debug.
5. Now, stepping on Dancepad buttons should send packets to the board.

Upon button press, the corresponding EVENTCODE packet will be sent.
Upon button release, EVENTCODE_IDLE packet will be sent.
*/

int main(int argc, char* argv[]) {

	char event_packet = EVENTCODE_IDLE;
	unsigned char buffer[20] = { 0x00 };
	unsigned char init[] = { 0x50, 0x00, 0x00, 0x05, 0x55 };
	HANDLE file;
	COMMTIMEOUTS timeouts;
	DWORD read, written;
	DCB port;
	HANDLE screen = GetStdHandle(STD_OUTPUT_HANDLE);
	DWORD mode;
	std::wstring port_name;
	size_t convertN;
	if (argc == 2) port_name = convert(argv[1]).c_str();
	else if (argc == 1) {
		printf("Enter the serial (COM) port to forward the event packets to: ");
		char tempbuf[100];
		fscanf_s(stdin, "%s", tempbuf);
		port_name = convert(tempbuf);
	}
	else {
		printf("Too many arguments!\n");
		exit(-1);
	}
	
	// open the comm port.
    file = CreateFile(port_name.c_str(),
        GENERIC_READ | GENERIC_WRITE,
        0, 
        NULL, 
        OPEN_EXISTING,
        0,
        NULL);
	if (INVALID_HANDLE_VALUE == file) {
		throw("failed to open port\n");
		exit(-1);
	}

	// get the current DCB, and adjust a few bits to our liking.
	memset(&port, 0, sizeof(port));
	port.DCBlength = sizeof(port);
	if (!GetCommState(file, &port)) {
		throw("failed to get comm state\n");
		exit(-1);
	}
	if (!BuildCommDCB(L"baud=9600 parity=n data=8 stop=1", &port)) {
		throw("failed to build comm DCB\n");
		exit(-1);
	}
	if (!SetCommState(file, &port)) {
		throw("failed to set port settings\n");
		exit(-1);
	}

	// set short timeouts on the comm port.
	timeouts.ReadIntervalTimeout = 1;
	timeouts.ReadTotalTimeoutMultiplier = 1;
	timeouts.ReadTotalTimeoutConstant = 1;
	timeouts.WriteTotalTimeoutMultiplier = 1;
	timeouts.WriteTotalTimeoutConstant = 1;
	if (!SetCommTimeouts(file, &timeouts)) {
		throw("failed to set port timeouts\n");
		exit(-1);
	}

	if (!EscapeCommFunction(file, CLRDTR)) {
		throw("failed to clear CLRDTR\n");
		exit(-1);
	}
	Sleep(200);
	if (!EscapeCommFunction(file, SETDTR)){
		throw("failed to set DTR\n");
		exit(-1);
	}
	
	if (!WriteFile(file, init, sizeof(init), &written, NULL)) {
		throw("failed to write data to port\n");
		exit(-1);
	}

	if (written != sizeof(init)) {
		throw("failed to write all data to port\n");
		exit(-1);
	}

	ALLEGRO_DISPLAY* display = nullptr;
	ALLEGRO_EVENT_QUEUE* event_queue = nullptr;
	ALLEGRO_JOYSTICK* joystick = nullptr;
	int num_joysticks;
	if (!al_init()) {
		throw("Failed to initialize Allegro.\n");
		exit(-1);
	}

	if (!al_install_keyboard()) {
		throw("Failed to install keyboard.\n");
		exit(-1);
	}

	if (!al_install_joystick()) {
		throw("Failed to install joystick.\n");
		exit(-1);
	}

	num_joysticks = al_get_num_joysticks();
	if (num_joysticks == 0) {
		printf("[CONFIG] Starting with no joysticks.\n");
	}
	else { 
		joystick = al_get_joystick(0);
	}

	event_queue = al_create_event_queue();
	if (!event_queue) {
		throw("Failed to create event queue.\n");
		exit(-1);
	}
	display = al_create_display(640, 480);

	if (!display) {
		throw("Failed to create display.\n");
		exit(-1);
	}

	al_set_window_title(display, "FPGA Dancepad Driver");

	al_register_event_source(event_queue, al_get_display_event_source(display));
	al_register_event_source(event_queue, al_get_keyboard_event_source());
	al_register_event_source(event_queue, al_get_joystick_event_source());

	printf("[HELP] Press H to see the full list of instructions.\n");

	// Event loop.
	bool done = false;
	bool print_event = false;
	while (!done) {
		ALLEGRO_EVENT event;
		al_wait_for_event(event_queue, &event);
		event_packet = EVENTCODE_IDLE;
		// On press.
		if (event.type == ALLEGRO_EVENT_KEY_DOWN && !key_state[event.keyboard.keycode]) {
			switch (event.keyboard.keycode) {
			case ALLEGRO_KEY_ESCAPE:
				printf("[CONFIG] Terminating program.\n");
				done = true;
				break;
			case ALLEGRO_KEY_D:
				if (print_event) printf("[CONFIG] Disabling event printing.\n");
				else printf("[CONFIG] Enabling event printing.\n");
				print_event = !print_event;
				break;
			case ALLEGRO_KEY_H:
				printf("\
[HELP] Instructions:\n\
\tEsc: Terminate the program.\n\
\tD: Toggle print for each event.\n\
\tH: Print instructions.\n");
				break;
			}
			key_state[event.keyboard.keycode] = true;
		} // On release.
		else if (event.type == ALLEGRO_EVENT_KEY_UP) {
			key_state[event.keyboard.keycode] = false;
		} // On hotplugging.
		else if (event.type == ALLEGRO_EVENT_JOYSTICK_CONFIGURATION) {
			if (print_event) printf("[EVENT] Reconfiguring joystick.\n");
			int old = al_get_num_joysticks();
			al_reconfigure_joysticks();
			num_joysticks = al_get_num_joysticks();
			if (old < num_joysticks) joystick = al_get_joystick(0);
		} // On press.
		else if (event.type == ALLEGRO_EVENT_JOYSTICK_BUTTON_DOWN && !joystick_button_state[event.joystick.button]) {
			switch (event.joystick.button) {
			case DANCEPAD_KEY_UP: // Up
				event_packet = EVENTCODE_UP;
				if (print_event) printf("[EVENT] Pressed up.\n");
				break;
			case DANCEPAD_KEY_DOWN: // Down
				event_packet = EVENTCODE_DOWN;
				if (print_event) printf("[EVENT] Pressed down.\n");
				break;
			case DANCEPAD_KEY_RIGHT: // Right
				event_packet = EVENTCODE_RIGHT;
				if (print_event) printf("[EVENT] Pressed right.\n");
				break;
			case DANCEPAD_KEY_LEFT: // Left
				event_packet = EVENTCODE_LEFT;
				if (print_event) printf("[EVENT] Pressed left.\n");
				break;
			case DANCEPAD_KEY_SELECT: // Select
				event_packet = EVENTCODE_SELECT;
				if (print_event) printf("[EVENT] Pressed select.\n");
				break;
			case DANCEPAD_KEY_START: // Start
				event_packet = EVENTCODE_START;
				if (print_event) printf("[EVENT] Pressed start.\n");
				break;
			default:
				if (print_event) printf("[EVENT] Unsupported button (ID: B%d).\n", event.joystick.button);
				break;
			}
			joystick_button_state[event.joystick.button] = true;
		} // On release.
		else if (event.type == ALLEGRO_EVENT_JOYSTICK_BUTTON_UP) {
			switch (event.joystick.button) {
			case DANCEPAD_KEY_UP: // Up

				if (print_event) printf("[EVENT] Released up.\n");
				break;
			case DANCEPAD_KEY_DOWN: // Down

				if (print_event) printf("[EVENT] Released down.\n");
				break;
			case DANCEPAD_KEY_RIGHT: // Right

				if (print_event) printf("[EVENT] Released right.\n");
				break;
			case DANCEPAD_KEY_LEFT: // Left

				if (print_event) printf("[EVENT] Released left.\n");
				break;
			case DANCEPAD_KEY_SELECT: // Select

				if (print_event) printf("[EVENT] Released select.\n");
				break;
			case DANCEPAD_KEY_START: // Start

				if (print_event) printf("[EVENT] Released start.\n");
				break;
			default:
				if (print_event) printf("[EVENT] Unsupported button released (ID: B%d).\n", event.joystick.button);
				break;
			}
			joystick_button_state[event.joystick.button] = false;
		}

		WriteFile(file, &event_packet, 1, &written, NULL);


	}

	al_destroy_event_queue(event_queue);
	al_destroy_display(display);
	al_uninstall_joystick();
	al_uninstall_keyboard();

	CloseHandle(file);
	return 0;
}
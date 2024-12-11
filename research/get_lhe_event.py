import argparse
import pylhe

def print_event_by_number(lhe_file_path, event_number):
    """
    Print details of a specific event from an LHE file based on the event number,
    and print the line number of that event in the file.

    :param lhe_file_path: Path to the LHE file.
    :param event_number: The event number to find (1-based index).
    """
    try:
        # Read the LHE file using read_lhe_file
        lhe_file = pylhe.read_lhe_file(lhe_file_path, with_attributes=True)

        # Open the LHE file to read line numbers
        with open(lhe_file_path, 'r') as file:
            lines = file.readlines()

        # Variable to keep track of the current event
        current_event_index = 1

        # Loop through the events
        for current_index, event in enumerate(lhe_file.events, start=1):
            if current_index == event_number:
                print(f"Details of Event {event_number} (Line {find_event_line_number(event_number, lines)}):\n")
                print(f"Number of particles: {len(event.particles)}\n")
                print("Particles:")
                for particle in event.particles:
                    print(f"  PID: {particle.id}, "
                          f"Px: {particle.px}, Py: {particle.py}, "
                          f"Pz: {particle.pz}, E: {particle.e}, "
                          f"Status: {particle.status}")
                return  # Exit after printing the desired event

        print(f"Event {event_number} not found. Total events may be fewer than {event_number}.")
    
    except Exception as e:
        print(f"An error occurred: {e}")

def find_event_line_number(event_number, lines):
    """
    Finds the line number where the event starts in the LHE file.

    :param event_number: The event number to find.
    :param lines: List of lines from the LHE file.
    :return: The line number where the event starts.
    """
    current_event_index = 0
    for i, line in enumerate(lines):
        # Look for event tags to identify where events start and end
        if '<event>' in line:
            current_event_index += 1
        if current_event_index == event_number:
            # Return the line number where this event starts
            return i + 1  # Line numbers are 1-based
    return -1  # Return -1 if the event number is not found

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Print details of a specific event from an LHE file.")
    parser.add_argument("lhe_file", type=str, help="Path to the input LHE file.")
    parser.add_argument("event_number", type=int, help="The event number to retrieve (1-based index).")

    # Parse arguments
    args = parser.parse_args()

    # Call the function with parsed arguments
    print_event_by_number(args.lhe_file, args.event_number)

if __name__ == "__main__":
    # Run the main function
    main()

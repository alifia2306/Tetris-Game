void lc4_putc(char c);		/* calls TRAP_PUTC, needs a character to write to display */
char lc4_getc();
void lc4_video_color(int n);
void lc4_video_box(int n, int col, int row);
void lc4_puts(char *s);		/* calls TRAP_PUTS, needs a string to write to display */


int main()
{
	int green_color = 992; 			// ASCII for green color
	int red_color = 31744; 			// ASCII for red color
	int black_color = 0;   			// ASCII for black color
	int blue_color = 31;   			// ASCII for blue color
	int white_color = 32767;		// ASCII for white color
	int last_row_boxes[12] = {0};	// To keep track of boxes in the last row
    int rows = 0;					// Row Coordinate
    int previous_row = 0;			// To keep track of previous Row
    int columns = 58;				// Column Coordinate
    int previous_col = 0;			// To keep track of previous Column
    char left = 'j';				// 'j' to move left
    char right = 'k';				// 'k' to move right
    char down = 'm';				// 'm' to move down
    int i = 0;
    int j = 0;
	int k = 0;
	int l = 0;
    char direction = 0;				// direction of move
	int colors[3] = {0};			// Array of colors
	int color_index = 0;			// color index to identify color
	int score = 0;					
	int box_number = 0;				// To find out if the box is in the last row
	int max_score = 0;	
	int last_row = 0;
	
	
	colors[0] = blue_color;
	colors[1] = red_color;
	colors[2] = green_color;
	
    lc4_video_color(black_color);

	// Loop for 10 boxes
    for(i = 0; i < 10; i++){

    	// Resetting column and row coordinates for each new box
        rows = 0;
        columns = 58;
		color_index = (color_index + 1) % 3;

		// Drawing new box
        lc4_video_box(colors[color_index], columns, rows);

        // Loop for movement of the box
        while((rows >= 0 && rows < 110) && (columns >= 8 && columns <= 118)){
	        direction = lc4_getc();

	        // Does not move if key pressed is not left, right or down
	        if(direction == left || direction == right || direction == down){
	            previous_row = rows;
	            previous_col = columns;
	            if (direction == left && columns >= 18){
	                columns = columns - 10;   
	            }
	            else if (direction == right && columns <= 108){
	                columns = columns + 10;
	            }
	            else if (direction == down && rows <= 90){
	                rows = rows + 10;
	            }
	            
	            // Moving the box 10 pixels down after pressing left, right or down.
	            if(rows <= 100){
	                rows = rows + 10;
	                lc4_video_box(black_color, previous_col, previous_row);
					
					box_number = (columns - 8) / 10;
					last_row = 110 - last_row_boxes[box_number] * 10;

					// To make sure entries in the row are not overlapped
					if (rows >= last_row) {
						rows = last_row;
						last_row_boxes[box_number]++;
						lc4_video_box(colors[color_index], columns, rows);
						break;
					}
					lc4_video_box(colors[color_index], columns, rows);
				}
			}
		}
    }

	columns = -1;
	score = 0;
	for (k = 0; k < 12; k++) {
		if (last_row_boxes[k] > 0) {

			// Keeps track of starting box
			if (columns == -1) 
				columns = k;
			score++;

		  //If no box, start with new score
		} else { 
			columns = -1;
			score = 0;
		}

		//Keep track of max score
		if (score > max_score) 
				max_score = score;
		if (score == 10)
				break;
	}
	
	//Prints max score
	lc4_puts("\nScore ");
	if (max_score == 10)
		lc4_puts("10");
	else
		lc4_putc(max_score + 48);
		
	if (score == 10) { // Erase all boxes from starting box
		for (k = columns; k < columns + 10 ; k++) {
			lc4_video_box(black_color, (10*k) + 8 , 110);
		}
	}
    return 0;
}

#include <windows.h>
#include <iostream>
#include <gl\GL.h>

#define offPOSX			0x0		//single
#define offPOSY			0x4
#define offPOSZ			0x8		
#define offHP			0x15C	//signed int
#define offNAME			0x250	//string length 16
#define offTEAM			0x354	//string length 5
#define offCN			0x1B4	//client number
#define offShootByte	0x1E0	
#define offSPEC			0x7C	//if 0x5 then isSpec = true
#define offEntityList	0x29CD34
#define offPlayerCount	0x29CD3C
#define offMeStruct		0x216454
#define offGamemode		0x1E5C28	//byte //reference http://sauerbraten.org/docs/game.html
#define offResX			0x29C1E8 	//probably unsigned int
#define offResY			0x29C1EC
#define offCAMX			0x3C
#define offFOV			0x297A2C
#define offMVPMatrix    0x297AF0
#define offShootDelay	0x174

__declspec(dllexport) void WINAPI Wichse();

DWORD SauerbratenBase = 0;
DWORD EntityList = 0;
DWORD PlayerCountAddress = 0;
DWORD ShootByteAddress = 0;

float* dbgcout;
DWORD* dwdbgcout;
DWORD* tmpptr;

bool EnableAim = true;

struct vec3_t {
	float x, y, z;
};

struct vec4 {
	float x, y, z, w;
};

class Player {
public:
	float x, y, z;
	DWORD Address = 0;
	int hp;
	char team[5];
	bool isSpec = false;
	char name[16];
	float camx;
	float camy;
	DWORD cn;
	int aimx;
	int aimy;
	DWORD addcamx, addcamy;

	void GetCameraAddress() {
		//["sauerbraten.exe" + 0216454] + 3C => addcamx
		tmpptr = (DWORD*)(SauerbratenBase + offMeStruct);
		addcamx = *tmpptr + offCAMX;
		addcamy = addcamx + 0x4;
	}
	void  SetCamera() {
		float* camxadd;
		float* camyadd;
		camxadd = (float*)addcamx;
		camyadd = (float*)addcamy;

		*camxadd = camx;
		*camyadd = camy;
		/*
		WPM<float>(addcamx, camx);
		WPM<float>(addcamy, camy);
		*/
	}

	void CalibrateMouse() {
		POINT m;
		GetCursorPos(&m);
		aimx = m.x;
		aimy = m.y;
	}

}Enemy[32], Me;

class ESP_c {
public:
	unsigned int winx, winy, drawx, drawy;
	DWORD resx = 1280, resy = 720;
	unsigned int fovx, fovy;
	//bool dcGot = false;
	//HDC dc;
	unsigned int scrx, scry;




	//HBRUSH brush = CreateSolidBrush(RGB(0xFF, 0, 0));



	void InitVariables() {
		DWORD SDLBase = (DWORD)GetModuleHandle("SDL.dll");
		DWORD* sdlresx;
		DWORD* sdlresy;
		sdlresx = (DWORD*)(SDLBase + 0x4E090);
		sdlresy = (DWORD*)(SDLBase + 0x4E094);



		resx = *sdlresx;

		resy = *sdlresy;

		//MessageBox(0, "lol", "ja geht", 0);

		//HWND hWnd = FindWindow(0, "Cube 2: Sauerbraten");
		//if (!dcGot) {
		//	dc = GetDC(hWnd);
		//	dcGot = true;
		//}

		//RECT rect;



		//GetWindowRect(hWnd, &rect);


		//winx = rect.left + 3;
		//winy = rect.top + 30;

		//cout << "winx: " << winx << endl;

		//fovx = RPM<unsigned int>(SauerbratenBase + offFOV);
		//fovy = fovx / (resx / resy);
	}



	bool WorldToScreen(vec3_t pos)
	{
		float matrix[16];
		float* ftemp;
		for (int i = 0; i < 16; i++) {
			ftemp = (float*)(SauerbratenBase + offMVPMatrix + (4 * i));
			matrix[i] = *ftemp;
		}

		for (int i = 0; i < 16;i++) {
			dbgcout  = (float*)(0x10300 + (4 * i));
			*dbgcout = matrix[i];
		}
		//*dbgcout = (SauerbratenBase + offMVPMatrix + 4 * 0);
		//Matrix-vector Product, multiplying world(eye) coordinates by projection matrix = clipCoords
		vec4 clipCoords;
		clipCoords.x = pos.x*matrix[0] + pos.y*matrix[4] + pos.z*matrix[8] + matrix[12];
		clipCoords.y = pos.x*matrix[1] + pos.y*matrix[5] + pos.z*matrix[9] + matrix[13];
		clipCoords.z = pos.x*matrix[2] + pos.y*matrix[6] + pos.z*matrix[10] + matrix[14];
		clipCoords.w = pos.x*matrix[3] + pos.y*matrix[7] + pos.z*matrix[11] + matrix[15];

		if (clipCoords.w < 0.1f)
			return false;

		//perspective division, dividing by clip.W = Normalized Device Coordinates
		vec3_t NDC;
		NDC.x = clipCoords.x / clipCoords.w;
		NDC.y = clipCoords.y / clipCoords.w;
		NDC.z = clipCoords.z / clipCoords.w;

		//Transform to window coordinates
		scrx = (resx / 2 * NDC.x) + (NDC.x + resx / 2);
		dwdbgcout = (DWORD*)0x10350;
		*dbgcout = scrx;
		scry = -(resy / 2 * NDC.y) + (NDC.y + resy / 2);
		dwdbgcout = (DWORD*)0x10354;
		*dbgcout = scry;

		dwdbgcout = (DWORD*)0x10360;
		*dwdbgcout = resx;
		dwdbgcout = (DWORD*)0x10364;
		*dwdbgcout = resy; 

		return true;
	}

	void DrawDot(int x, int y, int width) {
	///	DrawBorderBox(x - (width / 2), y - (width / 2), 0, 0, width);
	}



	void DrawESPDotGL(int x, int y, int z, int hp) {
		vec3_t pos;

		int headscrx = 0;
		int headscry = 0;
		pos.x = x;
		pos.y = y;
		pos.z = z + 3.5f;

		//if (!WorldToScreen(pos)) {
		//	return;
		//}

		
		WorldToScreen(pos);
		headscrx = scrx;
		headscry = scry;
		pos.z -= 21;
		WorldToScreen(pos);
		int groundscry = scry;
		float height = groundscry - headscry;
		float width = height / 1.5;


		//DrawLine(resx / 2, resy, scrx, groundscry,RGB(0xFF,0,0));
		//resx = resx / 2;
		//thread t1(void DrawLine(int resx, int resy, int scrx, int groundscry));
		/////////DrawBorderBox(scrx - width / 2, headscry, width, height, 1);
		glColor3f(0.6, 0.0, 0.0);
		DrawBox(headscry, scrx - width / 2, groundscry, scrx + width / 2,2);

		/*glColor3f(0.25, 0.0, 0.0); */
		/*DrawLine(resx / 2, resy, scrx, groundscry, 0.2f);*///<- Snaplines

		glColor3f(0.0, 0.8, 0.0);
		DrawLine(scrx - (width / 2) - 4, groundscry, scrx - (width / 2) - 4, headscry + (((1.0f - ((float)hp / 100.0f))*height)), 3);
		//scrx = scrx - width / 2;
		//int thick = 2;
		//thread t2(void DrawBorderBox(int scrx,int headscry,int width,int height,int thick));
		//DrawLine(scrx - (width / 2) - 4, groundscry, scrx - (width / 2) - 4, headscry + (((1.0f - ((float)hp / 100.0f))*height)), 3, RGB(0, 0xFF, 0));

		//cout << "scrx: " << scrx << endl;
		//cout << "scry: " << scry << endl;
		//Sleep(10);
		//system("cls");
	}

	void DrawBox(int top, int left, int bottom, int right,int thickness) {
		DrawLine(left, top, right, top, thickness); //obere kante
		DrawLine(left, top, left, bottom, thickness); // linke
		DrawLine(left, bottom, right, bottom, thickness);//untere kante
		DrawLine(right, top, right, bottom, thickness);

	}

	void DrawLine(int StartX, int StartY, int EndX, int EndY, float thickness) {
		glLineWidth(thickness);
		glBegin(GL_LINES);
			glVertex2f((GLfloat)StartX, (GLfloat)StartY);
			glVertex2f((GLfloat)EndX, (GLfloat)EndY);
		glEnd();
	}

	


}ESP;

int GetPlayerCount() {
	int* temp;
	temp = (int*)PlayerCountAddress;
	int buffer = *temp;
	return buffer;
}

void GetEnemyData() {
	int PlayerCount = GetPlayerCount();
	DWORD* dwtemp;
	dwtemp = (DWORD*)EntityList;
	DWORD List = *dwtemp;
	//cout << "PlayerCount: " << PlayerCount << endl;
	//cout << "index\tx\ty\tz" << endl;


	for (int i = 1; i < PlayerCount;i++) {
		DWORD* tempce;
		tempce = (DWORD*)(List + 4 * i);
		DWORD AddressCurrentEnemy = *tempce;

		if (AddressCurrentEnemy != NULL) {
			float* fltemp;
			fltemp = (float*)(AddressCurrentEnemy + offPOSX);
			Enemy[i].x = *fltemp;
			fltemp = (float*)(AddressCurrentEnemy + offPOSY);
			Enemy[i].y = *fltemp;
			fltemp = (float*)(AddressCurrentEnemy + offPOSZ);
			Enemy[i].z = *fltemp;

			int* itemp;
			itemp = (int*)(AddressCurrentEnemy + offHP);
			Enemy[i].hp = *itemp;
			tempce = (DWORD*)(AddressCurrentEnemy + offCN);
			Enemy[i].cn = *tempce;
			Enemy[i].Address = AddressCurrentEnemy;


			/*~ check if the player is in spectator mode ~*/
			BYTE* btemp;
			btemp = (BYTE*)(AddressCurrentEnemy + offSPEC);
			BYTE SpecVal = *btemp;
			if (SpecVal == 0x5) {
				Enemy[i].isSpec = true;
			}
			else {
				Enemy[i].isSpec = false;
			}

			/*~ read team name ~*/

			char* ctemp;
			tempce = (DWORD*)(List + 4 * i);
			ctemp = (char*)(*tempce + offTEAM);

			for (int z = 0; z < 5; z++) {
				
				Enemy[i].team[z] = ctemp[z];
			}
		}


		//cout << i << "\t" << Enemy[i].x << "\t" << Enemy[i].y << "\t" << Enemy[i].z << endl;

	}


}

void GetMyData() {
	DWORD* tempadd;
	tempadd = (DWORD*)EntityList;
	DWORD List = *tempadd;
	DWORD* AddressMe;
	AddressMe = (DWORD*)List;

	float* tempx;
	tempx = (float*)(*AddressMe + offPOSX);
	Me.x = *tempx;

	tempx = (float*)(*AddressMe + offPOSY);
	Me.y = *tempx;

	tempx = (float*)(*AddressMe + offPOSZ);
	Me.z = *tempx;

    //Me.x = RPM<float>(AddressMe + offPOSX);
	//Me.y = RPM<float>(AddressMe + offPOSY);
	//Me.z = RPM<float>(AddressMe + offPOSZ);

	DWORD* MyTeamStringAdd;
	MyTeamStringAdd = (DWORD*)List;

	char* MyTeamString;
	MyTeamString = (char*)(*MyTeamStringAdd + offTEAM);

	for (int z = 0; z < 5; z++) {
		Me.team[z] = MyTeamString[z];
		//Me.team[z] = RPM<char>(RPM<DWORD>(List) + offTEAM + z);
	}
}

bool isTeamBased() {
	BYTE* btemp;
	btemp = (BYTE*)(SauerbratenBase + offGamemode);
	BYTE GameMode = *btemp;
	switch (GameMode) {
	case 0: return false; break; //ffa
	case 1: return false; break; //coop edit
	case 2: return true; break; //standart teamplay
	case 3: return false; break; //instagib
	case 4: return true; break; //instagib team
	case 5: return false; break; //effic
	case 6: return true; break; //effic team
	case 7: return false; break; //tactics
	case 8: return true; break; //tactics team
	case 9: return false; break; //capture??
	case 10: return false; break; //capture regen??
	case 11: return true; break; //ctf
	case 12: return true; break; //insta ctf
	case 13: return true; break; //protect
	case 14: return true; break; //insta protect
	case 15: return false; break; //hold
	case 16: return false; break; //hold insta
	case 17: return true; break; //effic ctf
	case 18: return true; break; //effic ctf
	case 19: return false; break; //ffa
	case 20: return true; break; //collect
	default: return false;break;
	}
}

int GetBestTarget(int Skip = 0) {
	int plrs = GetPlayerCount();
	float dist = 0;
	float distshortest = 99999.f;
	int BestTargetIndex = -1;
	/*
	if (Skip != 0) {
	cout << "SKIPPING : " << Skip << endl;
	}
	*/

	for (int i = 1; i < plrs; i++) {
		//if (Enemy[i].isSpec == false && Enemy[i].team[0] != Me.team[0] && Enemy[i].hp > 0) {
		if (Enemy[i].isSpec == false && Enemy[i].hp > 0) {
			if (Enemy[i].team[0] != Me.team[0] || !isTeamBased()) {

				//if (isEnemyInView(100, i)) {
				ESP.DrawESPDotGL(Enemy[i].x, Enemy[i].y, Enemy[i].z, Enemy[i].hp);
				//}



				//cout << "Spec: " << Enemy[i].isSpec << " Team: " << Enemy[i].team << " HP: " << Enemy[i].hp << endl;
				/*dist = fabsf(sqrtf(
					(Enemy[i].x - Me.x) * (Enemy[i].x - Me.x) +
					(Enemy[i].y - Me.y) * (Enemy[i].y - Me.y) +
					(Enemy[i].z - Me.z) * (Enemy[i].z - Me.z)
				));*/

				vec3_t TargetPos;
				TargetPos.x = Enemy[i].x;
				TargetPos.y = Enemy[i].y;
				TargetPos.z = Enemy[i].z;

				if (ESP.WorldToScreen(TargetPos)) {

					dist = fabsf(sqrtf(
						(ESP.scrx - ESP.resx / 2) * (ESP.scrx - ESP.resx / 2) +
						(ESP.scry - ESP.resy / 2) * (ESP.scry - ESP.resy / 2)
					));
					//cout << "Dist: " << dist << endl;

					if (dist < distshortest) {
						//if (isEnemyInView(100, i) || !OnlyAimAtEnemiesInView) {
						distshortest = dist;
						//cout << "AYYYYYY" << endl;
						BestTargetIndex = i;
						//}
					}
				}
			}
		}

	}
	/*
	if (Skip != 0) {
	cout << "Next Target is : " << BestTargetIndex << endl;
	}
	*/

	//cout << "index\tx\ty\tz" << endl;
	//cout << 0 << "\t" << Me.x << "\t" << Me.y << "\t" << Me.z << endl;
	//cout << "I:" << BestTargetIndex << "\tDist: " << distshortest << endl;
	return BestTargetIndex;
}

void Aim(int index) {

	//int NextTargetCycles = 0;
	float dx, dy, dz;
	//bool NewTarget = true;
	//while (NewTarget && GetAsyncKeyState(0x2)) {
	//NewTarget = false;
	dx = Enemy[index].x - Me.x;
	dy = Enemy[index].y - Me.y;
	dz = (Enemy[index].z - 1.7f) - Me.z;



	
	//std::cout << "AIMING AT Index: " << index << std::endl;
	//std::cout << "X: " << Enemy[index].x << std::endl;
	//std::cout << "y: " << Enemy[index].y << std::endl;
	//std::cout << "z: " << Enemy[index].z << std::endl;
	

	Me.camx = ((atan2(dy, dx) * 57.2958) - 90);
	
	//cout << "camx: " << Me.camx << endl;

	float dist = fabsf(sqrtf(
		(dx) * (dx)+
		(dy) * (dy)
	));

	Me.camy = (atan2(dz, dist) * 57.2958);

	
	if (index != -1) {
		Me.SetCamera();
	}

	





//	HDC dc = GetDC(0);
	//Sleep(1);
	/*
	if (GetPixel(dc, Me.aimx, Me.aimy) == 0x02FF00 ||
	GetPixel(dc, Me.aimx + 1, Me.aimy) == 0x02FF00 ||
	GetPixel(dc, Me.aimx - 1, Me.aimy) == 0x02FF00 ||
	GetPixel(dc, Me.aimx, Me.aimy + 1) == 0x02FF00 ||
	GetPixel(dc, Me.aimx, Me.aimy - 1) == 0x02FF00

	) */

	unsigned char pixel[4];
	glReadPixels(ESP.resx/2, ESP.resy/2, 1, 1, GL_RGB, GL_UNSIGNED_BYTE, pixel);
	//cout << "R: " << (int)pixel[0] << endl;
	//cout << "G: " << (int)pixel[1] << endl;
	//cout << "B: " << (int)pixel[2] << endl;
	unsigned char* dbgpixel;
	dbgpixel = (unsigned char*)0x10600;

	for (int i = 0; i < 4; i++) {
		dbgpixel[i] = pixel[i];
	}

	//if (GetPixel(dc, Me.aimx, Me.aimy) == 0x02FF00
	if(pixel[0] == 0x0 && pixel[1] == 0xFF && pixel[2] == 0x02)
	{
		//cout << "SHOOT!" << endl;


		//AU3_MouseClick(L"left");
		//WPM<BYTE>(ShootByteAddress, 0x1);
		BYTE* ShootBool;
		ShootBool = (BYTE*)ShootByteAddress;
		*ShootBool = 0x1;
		
		//WPM<BYTE>(ShootByteAddress, 0x0);

		

		//Sleep(10);

	}

	//DWORD* CurrentHP;
	//CurrentHP = (DWORD*)(Enemy[index].Address + offHP);
	//if (*CurrentHP <= 0) {

	//}

	

	//Sleep(250);
	//DeleteDC(dc);





	//if (NextTargetCycles > 1)
	//	break;
	//NextTargetCycles++;
	//}  //newtarget while loop



}

void init() {

		SauerbratenBase = (DWORD)GetModuleHandle("sauerbraten.exe");
		dbgcout = (float*)0x10300;
		
		EntityList = SauerbratenBase + offEntityList;
		PlayerCountAddress = SauerbratenBase + offPlayerCount;
		DWORD* SauerbaseUndShoot;
		SauerbaseUndShoot = (DWORD*)(SauerbratenBase + 0x216454);
		ShootByteAddress = *SauerbaseUndShoot + offShootByte;
		//*dbgcout = ShootByteAddress;
		Me.GetCameraAddress();

	/*
	string path = ExePath() ;
	string rest = "\\AutoItX3.dll";
	path = path + rest;


	HINSTANCE hGetProcIDDLL = LoadLibrary(path.c_str());
	if (!hGetProcIDDLL) {
	std::cout << "could not load the dynamic library AutoItX3.dll" << std::endl;
	system("pause");
	exit(0);
	}
	*/
	/*
	f_funci funci = (f_funci)GetProcAddress(hGetProcIDDLL, "funci");
	if (!funci) {
	std::cout << "could not locate the function" << std::endl;
	return EXIT_FAILURE;
	}
	*/
}

DWORD CheckDelay() {
	DWORD* tempadd;
	tempadd = (DWORD*)EntityList;
	DWORD List = *tempadd;
	DWORD* AddressMe;
	AddressMe = (DWORD*)List;

	DWORD* tempx;
	tempx = (DWORD*)(*AddressMe + offShootDelay);
	DWORD result = *tempx;

	
	
	/*
	DWORD* dbglist;
	dbglist = (DWORD*)0x10400;
	*dbglist = (DWORD)tempx;
	*/

	return result;
}



void WINAPI Wichse()
{
	init();
	ESP.InitVariables();
	GetEnemyData();
	GetMyData();
	

	if (GetAsyncKeyState(0x2) && EnableAim) {
		Aim(GetBestTarget());
	}
	else {
		GetBestTarget();
	}

	if (!GetAsyncKeyState(0x2)) {
		EnableAim = true;
	}

	if (CheckDelay() > 0) {
		BYTE* ShootBool;
		ShootBool = (BYTE*)ShootByteAddress;
		*ShootBool = 0x0;
		EnableAim = false;
	}



	glBegin(GL_LINES);
	glVertex2f(10, 10);
	glVertex2f(20, 20);
	glEnd();
}
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "cjson/cJSON.h"

int main(int argc, char* argv[])
{
    char* filepaths[] = {
        "/app/kpp_app_cmds.json",
        "/usr/share/app/kpp_sys_cmds.json",
        "/usr/share/webkit-1.0/pillow/debug_cmds.json",
        NULL
    };

    for (int i=0; filepaths[i] != NULL; i++)
    {
        printf("Patching '%s'...\n", filepaths[i]);
        if (access(filepaths[i], R_OK) != 0)
        {
            printf("Could not access '%s'\n", filepaths[i]);
            continue;
        }

        FILE* file = fopen(filepaths[i], "r+");
        if (file == NULL)
        {
            printf("Could not open '%s'\n", filepaths[i]);
            continue;
        }
        fseek(file, 0L, SEEK_END);
        int size = ftell(file) + 1;
        char* buffer = malloc(size + 1);

        if (buffer == NULL)
        {
            printf("Could not allocate %i bytes for '%s'\n", size+1, filepaths[i]);
            fclose(file);
            continue;
        }
        
        buffer[size+1] = 0;
        fseek(file, 0, SEEK_SET);
        fread(buffer, 1, size, file);

        cJSON* json = cJSON_Parse(buffer);
        if (json == NULL)
        {
            printf("Could not parse JSON for file contents:\n%s\n", buffer);
            fclose(file);
            continue;
        }

        if (cJSON_HasObjectItem(json, ";kpm"))
            cJSON_DeleteItemFromObject(json, ";kpm");

        if (cJSON_HasObjectItem(json, ";log"))
            cJSON_DeleteItemFromObject(json, ";log");

        cJSON_AddItemToObject(json, ";kpm", cJSON_CreateString("/var/local/kmc/sbin/kpm.sh"));
        cJSON_AddItemToObject(json, ";log", cJSON_CreateString("/usr/bin/logThis.sh"));
        
        char* patched_json = cJSON_Print(json);
        fseek(file, 0, SEEK_SET);
        fwrite(patched_json, 1, strlen(patched_json), file);
        ftruncate(fileno(file), strlen(patched_json));

        fclose(file);
        cJSON_Delete(json);
    }
    return 0;
}
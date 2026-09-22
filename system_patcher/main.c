#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "cjson/cJSON.h"

int main(int argc, char* argv[])
{
    for (int i=1; i < argc; i++)
    {
        printf("Patching '%s'...\n", argv[i]);

        FILE* file = fopen(argv[i], "r+");
        if (file == NULL)
        {
            printf("Could not open '%s'\n", argv[i]);
            continue;
        }

        fseek(file, 0, SEEK_END);
		long size = ftell(file);
		fseek(file, 0, SEEK_SET);

        char* buffer = malloc(size + 1);
        if (buffer == NULL)
        {
            printf("Could not allocate %ld bytes for '%s'\n", size+1, argv[i]);
            fclose(file);
            continue;
        }
        buffer[fread(buffer, 1, size, file)] = 0;

        cJSON* json = cJSON_Parse(buffer);
        if (json == NULL)
        {
            printf("Could not parse JSON for file contents:\n%s\n", buffer);
            free(buffer);
            fclose(file);
            continue;
        }
        free(buffer);

        if (cJSON_HasObjectItem(json, ";kpm"))
            cJSON_DeleteItemFromObject(json, ";kpm");

        if (cJSON_HasObjectItem(json, ";log"))
            cJSON_DeleteItemFromObject(json, ";log");

        if (cJSON_HasObjectItem(json, ";kmclog"))
            cJSON_DeleteItemFromObject(json, ";kmclog");

        cJSON_AddItemToObject(json, ";kpm", cJSON_CreateString("/var/local/kmc/sbin/kpm.sh"));
        cJSON_AddItemToObject(json, ";log", cJSON_CreateString("/var/local/kmc/sbin/logThis.sh"));
        cJSON_AddItemToObject(json, ";kmclog", cJSON_CreateString("/var/local/kmc/sbin/kmclog.sh"));
        
        char* patched_json = cJSON_Print(json);
        cJSON_Delete(json);
        if (patched_json == NULL)
        {
            printf("Could not serialise JSON for '%s'\n", argv[i]);
            fclose(file);
            continue;
        }

        fseek(file, 0, SEEK_SET);
        fwrite(patched_json, 1, strlen(patched_json), file);
        fflush(file);
        ftruncate(fileno(file), strlen(patched_json));

        free(patched_json);
        fclose(file);
    }
    return 0;
}
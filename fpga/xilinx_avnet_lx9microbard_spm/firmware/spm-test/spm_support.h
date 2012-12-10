#ifndef SPM_SUPPORT_H
#define SPM_SUPPORT_H

#ifndef SPM_ID
#error SPM_ID should be defined
#endif

#define STR(x)  #x
#define XSTR(x) STR(x)

#define SPM_TEXT_SECTION  .spm.SPM_ID.text
#define SPM_ENTRY_SECTION .spm.SPM_ID.text.entry
#define SPM_DATA_SECTION  .spm.SPM_ID.data

#define SPM_TEXT_SECTION_STR  XSTR(SPM_TEXT_SECTION)
#define SPM_ENTRY_SECTION_STR XSTR(SPM_ENTRY_SECTION)
#define SPM_DATA_SECTION_STR  XSTR(SPM_DATA_SECTION)

#define SPM_LABEL(id, label) spm_ ## id ## _ ## label
#define XSPM_LABEL(id, label) SPM_LABEL(id, label)

#define SPM_TEXT_START XSPM_LABEL(SPM_ID, text_start)
#define SPM_TEXT_END   XSPM_LABEL(SPM_ID, text_end)
#define SPM_DATA_START XSPM_LABEL(SPM_ID, data_start)
#define SPM_DATA_END   XSPM_LABEL(SPM_ID, data_end)

#ifndef __ASSEMBLER__

extern char SPM_TEXT_START;
extern char SPM_TEXT_END;
extern char SPM_DATA_START;
extern char SPM_DATA_END;

#define spm_text_start (void*)(&SPM_TEXT_START)
#define spm_text_end   (void*)(&SPM_TEXT_END)
#define spm_data_start (void*)(&SPM_DATA_START)
#define spm_data_end   (void*)(&SPM_DATA_END)

#endif // __ASSEMBLER__

#endif
